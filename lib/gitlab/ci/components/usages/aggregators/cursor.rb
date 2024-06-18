# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      module Usages
        module Aggregators
          # This class represents a Redis cursor that keeps track of the data processing
          # position and progression in Gitlab::Ci::Components::Usages::Aggregator. It
          # updates and saves the attributes necessary for the aggregation to resume
          # from where it was interrupted on its last run.
          #
          # The cursor's target_id is reset to 0 under these circumstances:
          # 1. When the Redis cursor is first initialized.
          # 2. When the Redis cursor expires or is lost and must be re-initialized.
          # 3. When the cursor advances past max_target_id.
          #
          ##### Attributes
          #
          # target_id: The target ID from which to resume aggregating the usage counts.
          # usage_window: The window of usage data to aggregate.
          # last_used_by_project_id: The last used_by_project_id that was counted before interruption.
          # last_usage_count: The last usage_count that was recorded before interruption.
          #
          # The last_used_by_project_id and last_usage_count only pertain to the exact target_id
          # and usage_window that was saved before interruption. If either of the latter attributes
          # change, then we reset the last_* values to 0.
          #
          class Cursor
            include Gitlab::Utils::StrongMemoize

            Window = Struct.new(:start_date, :end_date)

            CURSOR_REDIS_KEY_TTL = 7.days

            attr_reader :target_id, :usage_window, :last_used_by_project_id, :last_usage_count, :interrupted

            alias_method :interrupted?, :interrupted

            def initialize(redis_key:, target_model:, usage_window:)
              @redis_key = redis_key
              @target_model = target_model
              @usage_window = usage_window
              @interrupted = false

              fetch_initial_attributes!
            end

            def interrupt!(last_used_by_project_id:, last_usage_count:)
              @last_used_by_project_id = last_used_by_project_id
              @last_usage_count = last_usage_count
              @interrupted = true
            end

            def target_id=(target_id)
              reset_last_usage_attributes if target_id != self.target_id
              @target_id = target_id
            end

            def advance
              self.target_id += 1
              self.target_id = 0 if target_id > max_target_id
            end

            def attributes
              {
                target_id: target_id,
                usage_window: usage_window.to_h,
                last_used_by_project_id: last_used_by_project_id,
                last_usage_count: last_usage_count,
                max_target_id: max_target_id
              }
            end

            def save!
              Gitlab::Redis::SharedState.with do |redis|
                redis.set(redis_key, attributes.except(:max_target_id).to_json, ex: CURSOR_REDIS_KEY_TTL)
              end
            end

            private

            attr_reader :redis_key, :target_model

            def fetch_initial_attributes!
              data = Gitlab::Redis::SharedState.with do |redis|
                raw = redis.get(redis_key)
                raw.present? ? Gitlab::Json.parse(raw) : {}
              end.with_indifferent_access

              start_date = parse_date(data.dig(:usage_window, :start_date))
              end_date = parse_date(data.dig(:usage_window, :end_date))

              @target_id = data[:target_id].to_i
              @last_used_by_project_id = data[:last_used_by_project_id].to_i
              @last_usage_count = data[:last_usage_count].to_i

              reset_last_usage_attributes if usage_window != Window.new(start_date, end_date)
            end

            def reset_last_usage_attributes
              @last_used_by_project_id = 0
              @last_usage_count = 0
            end

            def max_target_id
              target_model.maximum(:id).to_i
            end
            strong_memoize_attr :max_target_id

            def parse_date(date_str)
              Date.parse(date_str) if date_str
            end
          end
        end
      end
    end
  end
end
