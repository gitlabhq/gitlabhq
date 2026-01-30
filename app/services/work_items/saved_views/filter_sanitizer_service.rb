# frozen_string_literal: true

module WorkItems
  module SavedViews
    class FilterSanitizerService < FilterBaseService
      attr_accessor :warnings
      attr_reader :sanitized_filters

      def initialize(filter_data:, namespace:, current_user:)
        @filters = filter_data.deep_dup.deep_symbolize_keys
        @container = namespace
        @current_user = current_user
        @warnings = []
        @sanitized_filters = {}
      end

      def execute
        validate_static_filters

        validate_assignee
        validate_author
        validate_not_author
        validate_or_author

        validate_labels
        validate_not_labels
        validate_or_labels

        validate_milestone
        validate_release

        validate_hierarchy
        validate_not_parent_ids

        validate_crm_organization_id
        validate_crm_contact_id

        validate_full_path

        ServiceResponse.success(payload: { filters: sanitized_filters, warnings: @warnings })
      rescue ArgumentError => e
        ServiceResponse.error(message: e.message)
      end

      private

      def validate_static_filters
        sanitized_filters.merge!(filters.slice(*self.class.static_filters))

        # Rename issue_types back to types for consistency with GraphQL input
        sanitized_filters[:types] = sanitized_filters.delete(:issue_types) if sanitized_filters.key?(:issue_types)

        # Handle static negated filters
        return unless filters[:not]

        sanitized_filters[:not] ||= {}
        sanitized_filters[:not].merge!(filters[:not].slice(*self.class.static_negated_filters))

        return unless sanitized_filters[:not].key?(:issue_types)

        sanitized_filters[:not][:types] = sanitized_filters[:not].delete(:issue_types)
      end

      # Simple cases using validate_with_context
      def validate_assignee
        validate_with_context(
          id_key: :assignee_ids,
          model: User,
          attribute: :username,
          output_key: :assignee_usernames,
          warning_label: 'assignee(s)'
        )
      end

      def validate_milestone
        validate_with_context(
          id_key: :milestone_ids,
          model: Milestone,
          attribute: :title,
          output_key: :milestone_title,
          warning_label: 'milestone(s)',
          unique: true
        )
      end

      def validate_release
        validate_with_context(
          id_key: :release_ids,
          model: Release,
          attribute: :tag,
          output_key: :release_tag,
          warning_label: 'release(s)'
        )
      end

      # Author - custom handling due to singular output and different OR key
      def validate_author
        return unless filters[:author_ids]

        found_records = User.id_in(filters[:author_ids])
        found_usernames = found_records.map(&:username)

        missing_count = filters[:author_ids].size - found_records.size
        add_warning(:author_username, "#{missing_count} author(s) not found") if missing_count > 0

        return unless found_usernames.any?

        sanitized_filters[:author_username] = found_usernames.size == 1 ? found_usernames.first : found_usernames
      end

      def validate_not_author
        validate_negated_id_to_attribute(id_key: :author_ids, model: User, attribute: :username,
          output_key: :author_username, warning_label: 'author(s)')
      end

      def validate_or_author
        return unless filters.dig(:or, :author_ids)

        found_records = User.id_in(filters[:or][:author_ids])
        found_usernames = found_records.map(&:username)

        missing_count = filters[:or][:author_ids].size - found_records.size
        add_warning(:or_author_usernames, "#{missing_count} author(s) not found") if missing_count > 0

        return unless found_usernames.any?

        sanitized_filters[:or] ||= {}
        sanitized_filters[:or][:author_usernames] = found_usernames
      end

      # Labels - custom handling due to unique and different OR key
      def validate_labels
        validate_id_to_attribute(id_key: :label_ids, model: Label, attribute: :title, output_key: :label_name,
          warning_label: 'label(s)', unique: true)
      end

      def validate_not_labels
        validate_negated_id_to_attribute(id_key: :label_ids, model: Label, attribute: :title, output_key: :label_name,
          warning_label: 'label(s)', unique: true)
      end

      def validate_or_labels
        return unless filters.dig(:or, :label_ids)

        found_records = Label.id_in(filters[:or][:label_ids])
        found_titles = found_records.map(&:title).uniq

        missing_count = filters[:or][:label_ids].size - found_records.size
        add_warning(:or_label_names, "#{missing_count} label(s) not found") if missing_count > 0

        return unless found_titles.any?

        sanitized_filters[:or] ||= {}
        sanitized_filters[:or][:label_names] = found_titles
      end

      def validate_hierarchy
        return unless filters[:hierarchy_filters]

        hierarchy_filters = filters[:hierarchy_filters]
        sanitized_hierarchy = {}

        if hierarchy_filters[:work_item_parent_ids].present?
          found_parents = WorkItem.id_in(hierarchy_filters[:work_item_parent_ids])

          missing_count = hierarchy_filters[:work_item_parent_ids].size - found_parents.size
          add_warning(:parent_ids, "#{missing_count} parent work item(s) not found") if missing_count > 0

          if found_parents.any?
            sanitized_hierarchy[:parent_ids] = found_parents.map do |parent|
              Gitlab::GlobalId.build(parent, id: parent.id).to_s
            end
          end
        end

        if hierarchy_filters[:parent_wildcard_id].present?
          sanitized_hierarchy[:parent_wildcard_id] = hierarchy_filters[:parent_wildcard_id]
        end

        if hierarchy_filters.key?(:include_descendant_work_items)
          sanitized_hierarchy[:include_descendant_work_items] = hierarchy_filters[:include_descendant_work_items]
        end

        sanitized_filters[:hierarchy_filters] = sanitized_hierarchy if sanitized_hierarchy.any?
      end

      def validate_not_parent_ids
        return unless filters.dig(:not, :parent_ids)

        found_parents = WorkItem.id_in(filters[:not][:parent_ids])

        missing_count = filters[:not][:parent_ids].size - found_parents.size
        add_warning(:not_parent_ids, "#{missing_count} parent work item(s) not found") if missing_count > 0

        return unless found_parents.any?

        sanitized_filters[:not] ||= {}
        sanitized_filters[:not][:parent_ids] = found_parents.map do |parent|
          Gitlab::GlobalId.build(parent, id: parent.id).to_s
        end
      end

      def validate_crm_contact_id
        return unless filters[:crm_contact_id]

        if CustomerRelations::IssueContact.exists?(contact_id: filters[:crm_contact_id]) # rubocop:disable CodeReuse/ActiveRecord -- TODO: Model scope?
          sanitized_filters[:crm_contact_id] = filters[:crm_contact_id]
        else
          add_warning(:crm_contact_id, "CRM contact not found")
        end
      end

      def validate_crm_organization_id
        return unless filters[:crm_organization_id]

        if CustomerRelations::Contact.exists?(organization_id: filters[:crm_organization_id]) # rubocop:disable CodeReuse/ActiveRecord -- TODO: Model scope?
          sanitized_filters[:crm_organization_id] = filters[:crm_organization_id]
        else
          add_warning(:crm_organization_id, "CRM organization not found")
        end
      end

      def validate_full_path
        return unless filters[:namespace_id]

        routable = Group.find_by_id(filters[:namespace_id])

        # If not a group, try to find a ProjectNamespace and get its project
        unless routable
          project_namespace = Namespaces::ProjectNamespace.find_by_id(filters[:namespace_id])
          routable = project_namespace&.project
        end

        return add_warning(:full_path, "Group / Project not found") unless routable

        sanitized_filters[:full_path] = routable.full_path
      end

      # Validates regular, negated, and OR contexts for simple cases
      def validate_with_context(id_key:, model:, attribute:, output_key:, warning_label:, unique: false)
        # Regular context
        validate_id_to_attribute(id_key: id_key, model: model, attribute: attribute,
          output_key: output_key, warning_label: warning_label, unique: unique)

        # Negated context
        validate_negated_id_to_attribute(id_key: id_key, model: model, attribute: attribute,
          output_key: output_key, warning_label: warning_label, unique: unique)

        # OR context
        return unless filters.dig(:or, id_key)

        found_attributes = find_records_and_attributes(filters[:or][id_key], model, attribute, unique: unique)
        add_missing_warning(:"or_#{output_key}", filters[:or][id_key].size, found_attributes.size, warning_label)

        return unless found_attributes.any?

        sanitized_filters[:or] ||= {}
        sanitized_filters[:or][output_key] = found_attributes
      end

      def validate_id_to_attribute(id_key:, model:, attribute:, output_key:, warning_label:, unique: false)
        return unless filters[id_key]

        found_attributes = find_records_and_attributes(filters[id_key], model, attribute, unique: unique)
        add_missing_warning(output_key, filters[id_key].size, found_attributes.size, warning_label)

        sanitized_filters[output_key] = found_attributes if found_attributes.any?
      end

      def validate_negated_id_to_attribute(id_key:, model:, attribute:, output_key:, warning_label:, unique: false)
        return unless filters.dig(:not, id_key)

        found_attributes = find_records_and_attributes(filters[:not][id_key], model, attribute, unique: unique)
        add_missing_warning(:"not_#{output_key}", filters[:not][id_key].size, found_attributes.size, warning_label)

        return unless found_attributes.any?

        sanitized_filters[:not] ||= {}
        sanitized_filters[:not][output_key] = found_attributes
      end

      def find_records_and_attributes(ids, model, attribute, unique: false)
        found_attributes = model.id_in(ids).map(&attribute)
        unique ? found_attributes.uniq : found_attributes
      end

      def add_missing_warning(field, expected_count, found_count, warning_label)
        missing_count = expected_count - found_count
        add_warning(field, "#{missing_count} #{warning_label} not found") if missing_count > 0
      end

      def add_warning(field, message)
        warnings << { field: field, message: message }
      end
    end
  end
end

WorkItems::SavedViews::FilterSanitizerService.prepend_mod
