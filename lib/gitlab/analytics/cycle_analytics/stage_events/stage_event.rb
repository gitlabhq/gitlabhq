# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Base class for expressing an event that can be used for a stage.
        class StageEvent
          include Gitlab::CycleAnalytics::MetricsTables
          extend Gitlab::Utils::Override

          delegate :label_based?, to: :class

          def initialize(params)
            @params = params
          end

          def self.name
            raise NotImplementedError
          end

          def html_description(options = {})
            self.class.name
          end

          def self.identifier
            raise NotImplementedError
          end

          def object_type
            raise NotImplementedError
          end

          def hash_code
            Digest::SHA256.hexdigest(self.class.identifier.to_s)
          end

          # Each StageEvent must expose a timestamp or a timestamp like expression in order to build a range query.
          # Example: get me all the Issue records between start event end end event
          def timestamp_projection
            columns = column_list

            columns.one? ? columns.first : Arel::Nodes::NamedFunction.new('COALESCE', columns)
          end

          # List of columns that are referenced in the `timestamp_projection` expression
          # Example timestamp projection: COALESCE(issue_metrics.created_at, issue_metrics.updated_at)
          # Expected column list: issue_metrics.created_at, issue_metrics.updated_at
          def column_list
            raise NotImplementedError
          end

          # Optionally a StageEvent may apply additional filtering or join other tables on the base query.
          def apply_query_customization(query)
            query
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_negated_query_customization(query)
            query.where(timestamp_projection.eq(nil))
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def include_in(query, **)
            query
          end

          def self.label_based?
            false
          end

          private

          attr_reader :params
        end
      end
    end
  end
end
