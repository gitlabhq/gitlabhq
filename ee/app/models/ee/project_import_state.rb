module EE
  module ProjectImportState
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      BACKOFF_PERIOD = 24.seconds
      JITTER = 6.seconds

      delegate :mirror?, to: :project

      before_validation :set_next_execution_to_now, on: :create

      state_machine :status, initial: :none do
        before_transition [:none, :finished, :failed] => :scheduled do |state, _|
          state.last_update_scheduled_at = Time.now
        end

        before_transition scheduled: :started do |state, _|
          state.last_update_started_at = Time.now
        end

        before_transition scheduled: :failed do |state, _|
          if state.mirror?
            state.last_update_at = Time.now
            state.set_next_execution_to_now
          end
        end

        after_transition started: :failed do |state, _|
          if state.mirror? && state.retry_limit_exceeded?
            ::NotificationService.new.mirror_was_hard_failed(state.project)
          end
        end

        after_transition [:scheduled, :started] => [:finished, :failed] do |state, _|
          ::Gitlab::Mirror.decrement_capacity(state.project_id) if state.mirror?
        end

        before_transition started: :failed do |state, _|
          if state.mirror?
            state.last_update_at = Time.now
            state.increment_retry_count
            state.set_next_execution_timestamp
          end
        end

        before_transition started: :finished do |state, _|
          if state.mirror?
            timestamp = Time.now
            state.last_update_at = timestamp
            state.last_successful_update_at = timestamp

            state.reset_retry_count
            state.set_next_execution_timestamp
          end

          if ::Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing?
            state.run_after_commit do
              last_indexed_commit = state.project.index_status&.last_commit
              ElasticCommitIndexerWorker.perform_async(state.project_id, last_indexed_commit)
            end
          end
        end

        after_transition [:finished, :failed] => [:scheduled, :started] do |state, _|
          ::Gitlab::Mirror.increment_capacity(state.project_id) if state.mirror?
        end
      end
    end

    def reset_retry_count
      self.retry_count = 0
    end

    def increment_retry_count
      self.retry_count += 1
    end

    # We schedule the next sync time based on the duration of the
    # last mirroring period and add it a fixed backoff period with a random jitter
    def set_next_execution_timestamp
      timestamp = Time.now
      retry_factor = [1, self.retry_count].max
      delay = [base_delay(timestamp), ::Gitlab::Mirror.min_delay].max
      delay = [delay * retry_factor, ::Gitlab::Mirror.max_delay].min

      self.next_execution_timestamp = timestamp + delay
    end

    def set_next_execution_to_now
      return unless project.mirror?

      self.next_execution_timestamp = Time.now
    end

    def retry_limit_exceeded?
      self.retry_count > ::Gitlab::Mirror::MAX_RETRY
    end

    private

    def base_delay(timestamp)
      return 0 unless self.last_update_started_at

      duration = timestamp - self.last_update_started_at

      (BACKOFF_PERIOD + rand(JITTER)) * duration.seconds
    end
  end
end
