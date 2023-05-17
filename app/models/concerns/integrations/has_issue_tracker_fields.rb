# frozen_string_literal: true

module Integrations
  module HasIssueTrackerFields
    extend ActiveSupport::Concern

    included do
      self.field_storage = :data_fields

      field :project_url,
        required: true,
        title: -> { _('Project URL') },
        help: -> do
          s_('IssueTracker|The URL to the project in the external issue tracker.')
        end

      field :issues_url,
        required: true,
        title: -> { s_('IssueTracker|Issue URL') },
        help: -> do
          ERB::Util.html_escape(
            s_('IssueTracker|The URL to view an issue in the external issue tracker. Must contain %{colon_id}.')
          ) % {
            colon_id: '<code>:id</code>'.html_safe
          }
        end

      field :new_issue_url,
        required: true,
        title: -> { s_('IssueTracker|New issue URL') },
        help: -> do
          s_('IssueTracker|The URL to create an issue in the external issue tracker.')
        end
    end
  end
end
