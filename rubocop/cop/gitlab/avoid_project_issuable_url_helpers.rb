# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Flags usages of project_issue_url, project_issue_path, project_work_item_url,
      # and project_work_item_path helpers, which raise errors for group-level issues.
      #
      # @example
      #   # bad
      #   project_issue_url(project, issue)
      #   project_issue_path(project, issue)
      #   project_work_item_url(project, work_item)
      #   project_work_item_path(project, work_item)
      #
      #   # good
      #   Gitlab::UrlBuilder.build(issue)
      #   Gitlab::UrlBuilder.build(issue, only_path: true)
      class AvoidProjectIssuableUrlHelpers < RuboCop::Cop::Base
        MSG = 'Avoid using `%<method>s`. Use `Gitlab::UrlBuilder.build(issue)` for a full URL ' \
          'or `Gitlab::UrlBuilder.build(issue, only_path: true)` for a path.'

        RESTRICT_ON_SEND = %i[
          project_issue_url
          project_issue_path
          project_work_item_url
          project_work_item_path
        ].freeze

        def on_send(node)
          add_offense(node.loc.selector, message: format(MSG, method: node.method_name))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
