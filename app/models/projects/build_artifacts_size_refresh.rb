# frozen_string_literal: true

module Projects
  class BuildArtifactsSizeRefresh < ApplicationRecord
    include AfterCommitQueue
    include BulkInsertSafe

    STALE_WINDOW = 2.hours

    # This delay is set to 10 minutes to accommodate any ongoing
    # deletion that might have happened.
    # The delete on the database may have been committed before
    # the refresh completed its batching. If the resulting decrement is
    # pushed into Redis after the refresh has ended, it would result in net negative value.
    # The delay is needed to ensure this negative value is ignored.
    FINALIZE_DELAY = 10.minutes

    self.table_name = 'project_build_artifacts_size_refreshes'

    COUNTER_ATTRIBUTE_NAME = :build_artifacts_size

    belongs_to :project

    validates :project, presence: true

    # The refresh of the project statistics counter is performed in 4 stages:
    # 1. created - The refresh is on the queue to be processed by Projects::RefreshBuildArtifactsSizeStatisticsWorker
    # 2. running - The refresh is ongoing. The project statistics counter switches to the temporary refresh counter key.
    #    Counter increments are deduplicated.
    # 3. pending - The refresh is pending to be picked up by Projects::RefreshBuildArtifactsSizeStatisticsWorker again.
    # 4. finalizing - The refresh has finished summing existing job artifact size into the refresh counter key.
    #    The sum will need to be moved into the counter key.
    STATES = {
      created: 1,
      running: 2,
      pending: 3,
      finalizing: 4
    }.freeze

    state_machine :state, initial: :created do
      # created -> running <-> pending
      state :created, value: STATES[:created]
      state :running, value: STATES[:running]
      state :pending, value: STATES[:pending]
      state :finalizing, value: STATES[:finalizing]

      event :process do
        transition [:created, :pending, :running] => :running
      end

      event :requeue do
        transition running: :pending
      end

      event :schedule_finalize do
        transition running: :finalizing
      end

      before_transition created: :running do |refresh|
        refresh.reset_project_statistics!
        refresh.refresh_started_at = Time.zone.now
        refresh.last_job_artifact_id_on_refresh_start = refresh.project.job_artifacts.last&.id
      end

      before_transition running: any do |refresh, transition|
        refresh.updated_at = Time.zone.now
      end

      before_transition running: :pending do |refresh, transition|
        refresh.last_job_artifact_id = transition.args.first
      end

      before_transition running: :finalizing do |refresh, transition|
        refresh.schedule_finalize_worker
      end
    end

    scope :stale, -> { with_state(:running).where('updated_at < ?', STALE_WINDOW.ago) }
    scope :remaining, -> { with_state(:created, :pending).or(stale) }
    scope :processing_queue, -> { remaining.order(state: :desc) }

    after_destroy :schedule_namespace_aggregation_worker

    def self.enqueue_refresh(projects)
      now = Time.zone.now

      records = Array(projects).map do |project|
        new(project: project, state: STATES[:created], created_at: now, updated_at: now)
      end

      bulk_insert!(records, skip_duplicates: true)
    end

    def self.process_next_refresh!
      next_refresh = nil

      transaction do
        next_refresh = processing_queue
          .lock('FOR UPDATE SKIP LOCKED')
          .take

        next_refresh&.process!
      end

      next_refresh
    end

    def reset_project_statistics!
      project.statistics.initiate_refresh!(COUNTER_ATTRIBUTE_NAME)
    end

    def next_batch(limit:)
      project.job_artifacts.select(:id, :size)
        .id_before(last_job_artifact_id_on_refresh_start)
        .id_after(last_job_artifact_id.to_i)
        .ordered_by_id
        .limit(limit)
    end

    def started?
      !created?
    end

    def finalize!
      project.statistics.finalize_refresh(COUNTER_ATTRIBUTE_NAME)

      destroy!
    end

    def schedule_finalize_worker
      run_after_commit do
        Projects::FinalizeProjectStatisticsRefreshWorker.perform_in(FINALIZE_DELAY, self.class.to_s, id)
      end
    end

    private

    def schedule_namespace_aggregation_worker
      run_after_commit do
        Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
      end
    end
  end
end
