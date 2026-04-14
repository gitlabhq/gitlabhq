# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Preloads
        FEATURE_PRELOADS = {
          description: [:last_edited_by],
          assignees: [:assignees],
          labels: [:labels],
          milestone: [:milestone],
          start_and_due_date: [:dates_source]
        }.freeze

        PROJECT_FEATURE_PRELOADS = {
          milestone: [{ milestone: :project }]
        }.freeze

        GROUP_FEATURE_PRELOADS = {
          milestone: [{ milestone: :group }]
        }.freeze

        FIELD_PRELOADS = {
          author: [:author],
          work_item_type: [:work_item_type],
          duplicated_to_work_item_url: [:duplicated_to],
          moved_to_work_item_url: [:moved_to],
          promoted_to_epic_url: [:work_item_transition],
          web_url: [:author, :work_item_type],
          web_path: [:author, :work_item_type]
        }.freeze

        PROJECT_FIELD_PRELOADS = {
          create_note_email: [:project],
          reference: [{ namespace: :route }, { project: :namespace }],
          web_url: [{ namespace: :route }, { project: :namespace }],
          web_path: [{ namespace: :route }, { project: :namespace }],
          user_permissions: [:project],
          features: [:work_item_type, :project]
        }.freeze

        GROUP_FIELD_PRELOADS = {
          reference: [{ namespace: :route }],
          web_url: [{ namespace: :route }],
          web_path: [{ namespace: :route }],
          user_permissions: [:namespace],
          features: [:work_item_type, { namespace: :route }]
        }.freeze

        def preload_associations_for(field_keys, feature_keys, resource_parent)
          is_project = resource_parent.is_a?(::Project)

          context_field_preloads, context_feature_preloads =
            if is_project
              [PROJECT_FIELD_PRELOADS, PROJECT_FEATURE_PRELOADS]
            else
              [GROUP_FIELD_PRELOADS, GROUP_FEATURE_PRELOADS]
            end

          field_preloads = field_keys.flat_map do |field|
            FIELD_PRELOADS.fetch(field, []) + context_field_preloads.fetch(field, [])
          end

          feature_preloads = feature_keys.flat_map do |feature|
            FEATURE_PRELOADS.fetch(feature, []) + context_feature_preloads.fetch(feature, [])
          end

          (field_preloads + feature_preloads).uniq
        end

        def build_work_items_relation(resource_parent, preloads: [])
          work_items_relation = ::WorkItems::WorkItemsFinder.new(
            current_user,
            work_items_finder_params(resource_parent)
          ).execute

          return work_items_relation if preloads.blank?

          work_items_relation.preload(*preloads) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
        end

        private

        def work_items_finder_params(resource_parent)
          base_params = if resource_parent.is_a?(::Project)
                          { project_id: resource_parent.id }
                        else
                          { group_id: resource_parent.id }
                        end

          transformer = ::API::Helpers::WorkItemsFilterParams.new(params)
          filter_params = transformer.transform

          base_params.merge(filter_params).merge(sort: "#{params[:order_by]}_#{params[:sort]}")
        end
      end
    end
  end
end

API::Helpers::WorkItems::Preloads.prepend_mod
