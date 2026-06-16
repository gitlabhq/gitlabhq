# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Preloads
        WORK_ITEM_REFERENCE_PRELOADS = [
          :author,
          { project: { namespace: :route } },
          { namespace: { parent: :route } }
        ].freeze

        NOTE_REFERENCE_PRELOADS = %i[author project noteable updated_by system_note_metadata].freeze

        FEATURE_PRELOADS = {
          description: [:last_edited_by],
          assignees: [:assignees],
          labels: [:labels],
          milestone: [:milestone],
          start_and_due_date: [:dates_source],
          time_tracking: [{ timelogs: :user }],
          error_tracking: [:sentry_issue],
          hierarchy: [{ work_item_parent: WORK_ITEM_REFERENCE_PRELOADS }],
          notifications: [:issue_assignees]
        }.freeze

        PROJECT_FEATURE_PRELOADS = {
          milestone: [{ milestone: :project }]
        }.freeze

        GROUP_FEATURE_PRELOADS = {
          milestone: [{ milestone: :group }]
        }.freeze

        FIELD_PRELOADS = {
          author: [:author],
          duplicated_to_work_item_url: [:duplicated_to],
          moved_to_work_item_url: [:moved_to],
          promoted_to_epic_url: [:work_item_transition],
          web_url: [:author],
          web_path: [:author],
          namespace: [{ namespace: :route }]
        }.freeze

        PROJECT_FIELD_PRELOADS = {
          create_note_email: [:project],
          reference: [{ namespace: :route }, { project: :namespace }],
          web_url: [{ namespace: :route }, { project: :namespace }],
          web_path: [{ namespace: :route }, { project: :namespace }],
          user_permissions: [:project],
          features: [:project]
        }.freeze

        GROUP_FIELD_PRELOADS = {
          reference: [{ namespace: :route }],
          web_url: [{ namespace: :route }],
          web_path: [{ namespace: :route }],
          user_permissions: [:namespace],
          features: [{ namespace: :route }]
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

        def preload_hierarchy_authorization(work_items, feature_keys)
          return unless current_user
          return unless feature_keys.include?(:hierarchy)
          return if work_items.blank?

          parents = work_items.filter_map do |work_item|
            next unless work_item.has_widget?(:hierarchy)

            work_item.get_widget(:hierarchy).parent
          end

          return if parents.empty?

          projects = parents.filter_map(&:project)
          ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute if projects.any?

          group_namespaces = (parents.map(&:namespace) + projects.map(&:namespace))
            .select { |namespace| namespace.type == ::Group.sti_name }
          return if group_namespaces.empty?

          ::Preloaders::GroupPolicyPreloader.new(group_namespaces, current_user).execute
        end

        def build_work_items_relation(resource_parent, preloads: [])
          work_items_relation = ::WorkItems::WorkItemsFinder.new(
            current_user,
            work_items_finder_params(resource_parent)
          ).execute

          return work_items_relation if preloads.blank?

          work_items_relation.preload(*preloads) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
        end

        def find_work_item_by_iid(resource_parent, iid)
          ::WorkItems::WorkItemsFinder.new(
            current_user,
            work_items_parent_params(resource_parent).merge(iids: [iid])
          ).execute.first
        end

        def count_preloads_for(work_items, field_keys, feature_keys)
          preloads = {}
          if field_keys.include?(:user_discussions_count)
            preloads[:user_discussions_counts] = preload_user_discussions_counts(work_items)
          end

          preloads[:award_emoji_counts] = preload_award_emoji_counts(work_items) if feature_keys.include?(:award_emoji)

          preloads
        end

        def build_children_relation(parent_work_item, state: nil, preloads: [])
          relation = parent_work_item.work_item_children_by_relative_position
          relation = relation.with_state(state) if state.to_s.in?(%w[opened closed])

          # Unconditionally preload author and project / namespace / route so the :read_work_item policy check doesn't
          # N+1 when loading those associations
          all_preloads = (preloads + WORK_ITEM_REFERENCE_PRELOADS).uniq
          relation.preload(*all_preloads) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
        end

        def build_linked_items_relation(work_item, state: nil, link_type: nil, preloads: [])
          # Unconditionally preload author and project / namespace / route so the :read_work_item policy check doesn't
          # N+1 when loading those associations
          all_preloads = (preloads + WORK_ITEM_REFERENCE_PRELOADS).uniq

          relation = ::WorkItem.linked_items_for(work_item.id, link_type: link_type, preload: all_preloads)
          relation = relation.with_state(state) if state.to_s.in?(%w[opened closed])
          relation
        end

        def build_notes_relation(parent_work_item, notes_filter:)
          # Preload the associations Entities::Note serializes per row (author, project, noteable)
          # plus updated_by and system_note_metadata, otherwise rendering a page issues per-note
          # queries proportional to per_page.
          parent_work_item.notes
            .with_notes_filter(notes_filter)
            .preload(NOTE_REFERENCE_PRELOADS) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
            .reorder(order_options_with_tie_breaker) # rubocop:disable CodeReuse/ActiveRecord -- needed for stable ordering on `order_by` + `sort`
        end

        # Bulk-fetches Subscription rows for the given work items and current user so the
        # notifications feature entity can read each work item's subscribed state from memory
        # rather than triggering one query per item.
        def preload_notifications_subscriptions(work_items, feature_keys)
          return {} unless current_user && feature_keys.include?(:notifications) && work_items.present?

          ::Subscription
            .for_subscribables(work_items.map(&:id), ::WorkItem.polymorphic_name)
            .for_user(current_user)
            .index_by(&:subscribable_id)
        end

        # Preloads the project / group membership associated with the work items so the :read_project and :read_group
        # policy checks don't N+1 on membership lookups
        def preload_work_item_policies(work_items)
          return unless current_user
          return if work_items.blank?

          projects = work_items.filter_map(&:project)
          ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute if projects.any?

          group_namespaces = (work_items.map(&:namespace) + projects.map(&:namespace))
            .select { |namespace| namespace.type == ::Group.sti_name }
          return if group_namespaces.empty?

          ::Preloaders::GroupPolicyPreloader.new(group_namespaces, current_user).execute
        end

        private

        def preload_user_discussions_counts(work_items)
          return {} if work_items.empty?

          ::Note.count_for_collection(
            work_items.map(&:id),
            work_items.first.class.base_class.name,
            'COUNT(DISTINCT discussion_id) AS count'
          ).each_with_object({}) { |row, hash| hash[row.noteable_id] = row.count.to_i }
        end

        def preload_award_emoji_counts(work_items)
          return {} if work_items.empty?

          awardable_type = work_items.first.class.base_class.name
          ::AwardEmoji
            .votes_for_collection(work_items.map(&:id), awardable_type)
            .each_with_object({}) do |row, hash|
              counts = hash[row.awardable_id] ||= { up: 0, down: 0 }
              key = row.name == ::AwardEmoji::UPVOTE_NAME ? :up : :down
              counts[key] = row.count.to_i
            end
        end

        def work_items_parent_params(resource_parent)
          if resource_parent.is_a?(::Project)
            { project_id: resource_parent.id }
          else
            { group_id: resource_parent.id }
          end
        end

        def work_items_finder_params(resource_parent)
          transformer = ::API::Helpers::WorkItemsFilterParams.new(params, resource_parent: resource_parent)
          filter_params = transformer.transform

          work_items_parent_params(resource_parent)
            .merge(filter_params)
            .merge(sort: "#{params[:order_by]}_#{params[:sort]}")
        end
      end
    end
  end
end

API::Helpers::WorkItems::Preloads.prepend_mod
