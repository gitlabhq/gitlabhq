# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class RelationFactory < Base::RelationFactory
        OVERRIDES = {
          labels: :group_labels,
          priorities: :label_priorities,
          label: :group_label,
          parent: :epic,
          iterations_cadences: 'Iterations::Cadence'
        }.freeze

        EXISTING_OBJECT_RELATIONS = %i[
          epic
          epics
          milestone
          milestones
          label
          labels
          group_label
          group_labels
        ].freeze

        private

        def setup_models
          setup_note if @relation_name == :notes

          update_group_references
        end

        def invalid_relation?
          @relation_name == :namespace_settings
        end

        def update_group_references
          return unless self.class.existing_object_relations.include?(@relation_name)
          return unless @relation_hash['group_id']

          @relation_hash['group_id'] = @importable.id
        end

        def use_attributes_permitter?
          false
        end
      end
    end
  end
end
