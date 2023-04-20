# frozen_string_literal: true

module Ci
  class RunnerManager < Ci::ApplicationRecord
    include FromUnion
    include RedisCacheable
    include Ci::HasRunnerExecutor

    # For legacy reasons, the table name is ci_runner_machines in the database
    self.table_name = 'ci_runner_machines'

    # The `UPDATE_CONTACT_COLUMN_EVERY` defines how often the Runner Machine DB entry can be updated
    UPDATE_CONTACT_COLUMN_EVERY = (40.minutes)..(55.minutes)

    belongs_to :runner

    has_many :runner_manager_builds, inverse_of: :runner_manager, class_name: 'Ci::RunnerManagerBuild'
    has_many :builds, through: :runner_manager_builds, class_name: 'Ci::Build'
    belongs_to :runner_version, inverse_of: :runner_managers, primary_key: :version, foreign_key: :version,
      class_name: 'Ci::RunnerVersion'

    validates :runner, presence: true
    validates :system_xid, presence: true, length: { maximum: 64 }
    validates :version, length: { maximum: 2048 }
    validates :revision, length: { maximum: 255 }
    validates :platform, length: { maximum: 255 }
    validates :architecture, length: { maximum: 255 }
    validates :ip_address, length: { maximum: 1024 }
    validates :config, json_schema: { filename: 'ci_runner_config' }

    cached_attr_reader :version, :revision, :platform, :architecture, :ip_address, :contacted_at, :executor_type

    # The `STALE_TIMEOUT` constant defines the how far past the last contact or creation date a runner manager
    # will be considered stale
    STALE_TIMEOUT = 7.days

    scope :stale, -> do
      created_some_time_ago = arel_table[:created_at].lteq(STALE_TIMEOUT.ago)
      contacted_some_time_ago = arel_table[:contacted_at].lteq(STALE_TIMEOUT.ago)

      from_union(
        where(contacted_at: nil),
        where(contacted_some_time_ago),
        remove_duplicates: false).where(created_some_time_ago)
    end

    def self.online_contact_time_deadline
      Ci::Runner.online_contact_time_deadline
    end

    def self.stale_deadline
      STALE_TIMEOUT.ago
    end

    def heartbeat(values, update_contacted_at: true)
      ##
      # We can safely ignore writes performed by a runner heartbeat. We do
      # not want to upgrade database connection proxy to use the primary
      # database after heartbeat write happens.
      #
      ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
        values = values&.slice(:version, :revision, :platform, :architecture, :ip_address, :config, :executor) || {}
        values[:contacted_at] = Time.current if update_contacted_at
        if values.include?(:executor)
          values[:executor_type] = Ci::Runner::EXECUTOR_NAME_TO_TYPES.fetch(values.delete(:executor), :unknown)
        end

        new_version = values[:version]
        schedule_runner_version_update(new_version) if new_version && values[:version] != version

        merge_cache_attributes(values)

        # We save data without validation, it will always change due to `contacted_at`
        update_columns(values) if persist_cached_data?
      end
    end

    def status
      return :stale if stale?
      return :never_contacted unless contacted_at

      online? ? :online : :offline
    end

    private

    def online?
      contacted_at && contacted_at > self.class.online_contact_time_deadline
    end

    def stale?
      return false unless created_at

      [created_at, contacted_at].compact.max <= self.class.stale_deadline
    end

    def persist_cached_data?
      # Use a random threshold to prevent beating DB updates.
      contacted_at_max_age = Random.rand(UPDATE_CONTACT_COLUMN_EVERY)

      real_contacted_at = read_attribute(:contacted_at)
      real_contacted_at.nil? ||
        (Time.current - real_contacted_at) >= contacted_at_max_age
    end

    def schedule_runner_version_update(new_version)
      return unless new_version && Gitlab::Ci::RunnerReleases.instance.enabled?

      Ci::Runners::ProcessRunnerVersionUpdateWorker.perform_async(new_version)
    end
  end
end
