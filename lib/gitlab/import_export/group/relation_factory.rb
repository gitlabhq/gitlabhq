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
          user_contributions: :user,
          epic_lists: 'Boards::EpicList',
          epic_boards: 'Boards::EpicBoard'
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
          iteration
          iterations
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

        MILESTONE_TITLE_UPDATE_MSG = '[Project/Group Import] Updating milestone title - ' \
          'source title used by existing group or project milestone'

        private

        def setup_models
          case @relation_name
          when :notes then setup_note
          when :'Iterations::Cadence' then setup_iterations_cadence
          when :events then setup_event
          when :milestone, :milestones then ensure_milestone_title_is_unique
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

        def ensure_milestone_title_is_unique
          title = @relation_hash['title']
          return unless title.present?

          existing_milestone = Milestone.for_projects_and_groups(project_ids, group_ids)
    .find_by_title(title)

          return unless existing_milestone

          # If Milestone was created during this import - let ObjectBuilder reuse it
          return if existing_milestone.group_id == @importable.id

          new_milestone_title = unique_milestone_title(title)

          logger.info(
            message: MILESTONE_TITLE_UPDATE_MSG,
            importable_id: @importable.id,
            relation_key: @relation_name,
            existing_milestone_title: title,
            existing_group_id: existing_milestone.group_id,
            existing_project_id: existing_milestone.project_id,
            new_milestone_title: new_milestone_title
          )

          @relation_hash['title'] = new_milestone_title
        end

        def group_ids
          @group_ids ||= @importable.self_and_hierarchy.pluck(:id)
        end

        def project_ids
          @project_ids ||= @importable.all_project_ids.pluck(:id)
        end

        def unique_milestone_title(title)
          suffix = "(imported-#{SecureRandom.hex(1)}-#{Time.current.to_i})"
          "#{title} #{suffix}"
        end

        def logger
          @logger ||= ::Import::Framework::Logger.build
        end
      end
    end
  end
end
