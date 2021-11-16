# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        # This class makes it possible to add label filters to stage event tables
        class LabelFilter < Issuables::LabelFilter
          extend ::Gitlab::Utils::Override

          def initialize(stage:, project:, group:, **kwargs)
            @stage = stage

            super(project: project, group: group, **kwargs)
          end

          private

          attr_reader :stage

          override :label_link_query
          def label_link_query(target_model, label_ids: nil)
            join_column = target_model.arel_table[target_model.issuable_id_column]

            LabelLink.by_target_for_exists_query(stage.subject_class.name, join_column, label_ids)
          end
        end
      end
    end
  end
end
