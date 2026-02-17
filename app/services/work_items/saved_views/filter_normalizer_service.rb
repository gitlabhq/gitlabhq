# frozen_string_literal: true

module WorkItems
  module SavedViews
    class FilterNormalizerService < FilterBaseService
      include ::API::Concerns::Milestones::GroupProjectParams

      attr_reader :normalized_filters

      def initialize(filter_data:, container:, current_user:)
        @filters = filter_data.to_h
        @container = container
        @current_user = current_user
        @normalized_filters = {}
      end

      # Overridden in EE
      def execute
        normalize_static_filters

        normalize_usernames(:assignee_usernames, :assignee_ids)
        normalize_author_username
        normalize_label_names
        normalize_attribute(:milestone_title, :milestone_ids, method: :find_milestone_ids)
        normalize_attribute(:release_tag, :release_ids, method: :find_release_ids,
          condition: -> { container.is_a?(Project) })

        normalize_simple_id(:crm_contact_id)
        normalize_simple_id(:crm_organization_id)
        normalize_full_path

        normalize_hierarchy

        normalize_negated_parent_ids

        ServiceResponse.success(payload: normalized_filters)
      rescue ArgumentError => e
        ServiceResponse.error(message: e.message)
      end

      private

      def normalize_static_filters
        normalized_filters.merge!(filters.slice(*self.class.static_filters))

        return unless filters[:not]

        normalized_filters[:not] ||= {}
        normalized_filters[:not].merge!(filters[:not].slice(*self.class.static_negated_filters))
      end

      def normalize_usernames(input_key, output_key)
        normalize_with_context(input_key, output_key) do |usernames|
          User.by_username(usernames).map(&:id)
        end
      end

      # Normalize attributes with a custom finder method
      def normalize_attribute(input_key, output_key, method: nil, condition: nil)
        return if condition && !condition.call

        normalize_with_context(input_key, output_key) do |values|
          if block_given?
            yield values
          elsif method
            case method
            when :find_milestone_ids then find_milestone_ids(values)
            when :find_release_ids then find_release_ids(values)
            else
              raise ArgumentError, "Unknown normalization method: #{method}"
            end
          else
            raise ArgumentError, "Must provide either method: or a block"
          end
        end
      end

      # Normalize an attribute, and if applicable, it's negation (NOT) and union (OR)
      def normalize_with_context(input_key, output_key)
        normalized_filters[output_key] = yield(filters[input_key]) if filters[input_key]

        # Negated context
        if filters.dig(:not, input_key)
          normalized_filters[:not] ||= {}
          normalized_filters[:not][output_key] = yield(filters[:not][input_key])
        end

        # Unioned context (OR)
        return unless filters.dig(:or, input_key)

        normalized_filters[:or] ||= {}
        normalized_filters[:or][output_key] = yield(filters[:or][input_key])
      end

      def normalize_simple_id(key)
        return unless filters[key]

        normalized_filters[key] = filters[key]
      end

      def find_label_ids(label_names)
        root_namespace = container.root_ancestor

        finder_params = if root_namespace.is_a?(Group)
                          { group: root_namespace, include_descendant_groups: true, title: label_names }
                        else
                          { project: container, title: label_names }
                        end

        LabelsFinder.new(current_user, finder_params).execute.map(&:id)
      end

      def find_milestone_ids(titles)
        finder_params = { title: titles }
        milestones_finder_params = if container.is_a?(Project)
                                     finder_params.merge(project_finder_params(container, { include_ancestors: true }))
                                   else
                                     finder_params.merge(group_finder_params(container,
                                       { include_ancestors: true, include_descendants: true }))
                                   end

        MilestonesFinder.new(milestones_finder_params).execute.map(&:id)
      end

      def find_release_ids(tags)
        ReleasesFinder.new(container, current_user, tag: tags).execute.map(&:id)
      end

      def normalize_full_path
        return unless filters[:full_path]

        found_routable = Routable.find_by_full_path(filters[:full_path])
        return unless found_routable

        # Only support groups / projects
        return if found_routable.is_a?(Namespaces::UserNamespace)

        # Check if user can read the group or project before allowing them to save
        if found_routable.is_a?(Group)
          return unless Ability.allowed?(current_user, :read_group, found_routable)

          normalized_filters[:namespace_id] = found_routable.id
        else
          return unless Ability.allowed?(current_user, :read_project, found_routable)

          normalized_filters[:namespace_id] = found_routable.project_namespace_id
        end
      end

      def normalize_hierarchy
        return unless filters[:hierarchy_filters]

        hierarchy_filters = filters[:hierarchy_filters].to_h
        normalized_hierarchy = {}

        if hierarchy_filters[:parent_ids].present?
          normalized_hierarchy[:work_item_parent_ids] = hierarchy_filters[:parent_ids]
        end

        if hierarchy_filters[:parent_wildcard_id].present?
          normalized_hierarchy[:parent_wildcard_id] = hierarchy_filters[:parent_wildcard_id]
        end

        if hierarchy_filters.key?(:include_descendant_work_items)
          normalized_hierarchy[:include_descendant_work_items] = hierarchy_filters[:include_descendant_work_items]
        end

        normalized_filters[:hierarchy_filters] = normalized_hierarchy if normalized_hierarchy.any?
      end

      def normalize_author_username
        # Separate, since we use the plural in the unioned context
        normalize_with_context(:author_username, :author_ids) do |username_or_usernames|
          usernames = Array.wrap(username_or_usernames)
          User.by_username(usernames).map(&:id)
        end

        normalize_with_context(:author_usernames, :author_ids) do |usernames|
          User.by_username(usernames).map(&:id)
        end
      end

      def normalize_label_names
        # Label is passed differently in the GQL depending on the context (negated / unioned)
        normalize_with_context(:label_name, :label_ids) do |label_name_or_names|
          label_names = Array.wrap(label_name_or_names)
          find_label_ids(label_names)
        end

        return unless filters.dig(:or, :label_names)

        normalized_filters[:or] ||= {}
        normalized_filters[:or][:label_ids] = find_label_ids(filters[:or][:label_names])
      end

      def normalize_negated_parent_ids
        return unless filters.dig(:not, :parent_ids)

        normalized_filters[:not] ||= {}
        normalized_filters[:not][:parent_ids] = filters[:not][:parent_ids]
      end
    end
  end
end

WorkItems::SavedViews::FilterNormalizerService.prepend_mod
