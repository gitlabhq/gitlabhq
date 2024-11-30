# frozen_string_literal: true

module Import
  class PendingReassignmentAlertPresenter < Gitlab::View::Presenter::Simple
    include Gitlab::Utils::StrongMemoize
    include ActionView::Helpers::TagHelper
    include SafeFormatHelper

    presents ::BulkImport, as: :bulk_import

    def show_alert?
      Feature.enabled?(:importer_user_mapping, current_user) &&
        Feature.enabled?(:bulk_import_importer_user_mapping, current_user) &&
        groups_awaiting_placeholder_assignment.any?
    end

    def groups_awaiting_placeholder_assignment
      return [] unless bulk_import&.finished?

      namespaces = bulk_import.namespaces_with_unassigned_placeholders
      namespaces.select do |namespace|
        namespace.owners.include?(current_user)
      end
    end
    strong_memoize_attr :groups_awaiting_placeholder_assignment

    def group_names
      return '' if groups_awaiting_placeholder_assignment.empty?

      groups_awaiting_placeholder_assignment.collect(&:name).to_sentence
    end

    def source_hostname
      Gitlab::Utils.parse_url(bulk_import.configuration.url).host
    end

    def title
      s_('UserMapping|Placeholder users awaiting reassignment')
    end

    def body
      safe_format(
        s_('UserMapping|Placeholder users were created in ' \
          '%{group_names}. These users were assigned group memberships and ' \
          'contributions from %{source_hostname}. To reassign contributions from ' \
          'placeholder users to GitLab users, go to the "Members" page of %{group_links}.'),
        group_names: group_names,
        source_hostname: source_hostname,
        group_links: group_links
      )
    end

    def group_links
      placeholders = []
      tag_pairs = []

      groups_awaiting_placeholder_assignment.collect do |namespace|
        placeholders << "%{group_#{namespace.id}_link_start}#{namespace.name}%{group_#{namespace.id}_link_end}"
        tag_pairs << tag_pair(
          tag.a(href: group_group_members_path(namespace, tab: 'placeholders')),
          :"group_#{namespace.id}_link_start",
          :"group_#{namespace.id}_link_end"
        )
      end

      safe_format(placeholders.to_sentence, *tag_pairs)
    end
  end
end
