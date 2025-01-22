# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class RelationFactory < Base::RelationFactory
        OVERRIDES = {
          labels: :group_labels,
          label: :group_label,
          parent: :epic,
          iterations_cadences: 'Iterations::Cadence',
          user_contributions: :user
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

        RELATIONS_WITH_REWRITABLE_USERNAMES = %i[
          milestone
          milestones
          epic
          epics
          release
          releases
          note
          notes
        ].freeze

        private

        def setup_models
          case @relation_name
          when :notes then setup_note
          when :'Iterations::Cadence' then setup_iterations_cadence
          when :events then setup_event
          end

          update_group_references

          return unless RELATIONS_WITH_REWRITABLE_USERNAMES.include?(@relation_name) && @rewrite_mentions

          update_username_mentions(@relation_hash)
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

        def setup_iterations_cadence
          @relation_hash['automatic'] = false
        end

        def setup_event
          @relation_hash = {} if @relation_hash['author_id'].nil?
        end
      end
    end
  end
end
