# frozen_string_literal: true

module Integrations
  module HasIssueTrackerFields
    extend ActiveSupport::Concern

    included do
      field :project_url,
            required: true,
            storage: :data_fields,
            title: -> { _('Project URL') },
            help: -> { s_('IssueTracker|The URL to the project in the external issue tracker.') }

      field :issues_url,
            required: true,
            storage: :data_fields,
            title: -> { s_('IssueTracker|Issue URL') },
            help: -> do
              format s_('IssueTracker|The URL to view an issue in the external issue tracker. Must contain %{colon_id}.'),
                colon_id: '<code>:id</code>'.html_safe
            end

      field :new_issue_url,
            required: true,
            storage: :data_fields,
            title: -> { s_('IssueTracker|New issue URL') },
            help: -> { s_('IssueTracker|The URL to create an issue in the external issue tracker.') }
    end
  end
end
