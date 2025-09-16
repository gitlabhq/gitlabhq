# frozen_string_literal: true

module Namespaces
  module ArchiveHelper
    include NamespaceHelper

    def show_archived_banner?(namespace)
      return false unless namespace

      namespace.persisted? && namespace.self_or_ancestors_archived?
    end

    def archived_banner_message(namespace)
      return with_archived_ancestor_banner_message(namespace) if namespace.ancestors_archived?

      no_archived_ancestor_banner_message(namespace)
    end

    private

    def no_archived_ancestor_banner_message(namespace)
      messages = {
        group: _(
          'This group is archived. Its subgroups, projects, and data are %{strong_open}read-only%{strong_close}.'
        ),
        project: _('This project is archived. Its data is %{strong_open}read-only%{strong_close}.')
      }

      message = message_for_namespace(namespace, messages)
      safe_format(message, tag_pair(tag.strong, :strong_open, :strong_close))
    end

    def with_archived_ancestor_banner_message(namespace)
      messages = {
        group: _('The parent group is archived. This group and its data are %{strong_open}read-only%{strong_close}.'),
        project: _(
          'The parent group is archived. This project and its data are %{strong_open}read-only%{strong_close}.'
        )
      }

      message = message_for_namespace(namespace, messages)
      safe_format(message, tag_pair(tag.strong, :strong_open, :strong_close))
    end
  end
end
