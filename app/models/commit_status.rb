class CommitStatus < ActiveRecord::Base
  include Statuseable
  include Importable

  self.table_name = 'ci_builds'

  belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id, touch: true
  belongs_to :user

  delegate :commit, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?

  validates_presence_of :name

  alias_attribute :author, :user

  scope :latest, -> do
    max_id = unscope(:select).select("max(#{quoted_table_name}.id)")

    where(id: max_id.group(:name, :commit_id))
  end
  scope :retried, -> { where.not(id: latest) }
  scope :ordered, -> { order(:name) }
  scope :ignored, -> { where(allow_failure: true, status: [:failed, :canceled]) }

  state_machine :status, initial: :pending do
    event :queue do
      transition skipped: :pending
    end

    event :run do
      transition pending: :running
    end

    event :drop do
      transition [:pending, :running] => :failed
    end

    event :success do
      transition [:pending, :running] => :success
    end

    event :cancel do
      transition [:pending, :running] => :canceled
    end

    after_transition pending: :running do |commit_status|
      commit_status.update_attributes started_at: Time.now
    end

    after_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.update_attributes finished_at: Time.now
    end

    after_transition [:pending, :running] => :success do |commit_status|
      MergeRequests::MergeWhenBuildSucceedsService.new(commit_status.pipeline.project, nil).trigger(commit_status)
    end

    after_transition any => :failed do |commit_status|
      MergeRequests::AddTodoWhenBuildFailsService.new(commit_status.pipeline.project, nil).execute(commit_status)
    end
  end

  delegate :sha, :short_sha, to: :pipeline

  def before_sha
    pipeline.before_sha || Gitlab::Git::BLANK_SHA
  end

  def self.stages
    # We group by stage name, but order stages by theirs' index
    unscoped.from(all, :sg).group('stage').order('max(stage_idx)', 'stage').pluck('sg.stage')
  end

  def self.stages_status
    # We execute subquery for each stage to calculate a stage status
    statuses = unscoped.from(all, :sg).group('stage').pluck('sg.stage', all.where('stage=sg.stage').status_sql)
    statuses.inject({}) do |h, k|
      h[k.first] = k.last
      h
    end
  end

  def ignored?
    allow_failure? && (failed? || canceled?)
  end

  def duration
    duration =
      if started_at && finished_at
        finished_at - started_at
      elsif started_at
        Time.now - started_at
      end
    duration
  end

  def stuck?
    false
  end
end
