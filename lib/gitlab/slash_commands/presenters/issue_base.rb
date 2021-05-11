# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      module IssueBase
        def color(issuable)
          issuable.open? ? '#38ae67' : '#d22852'
        end

        def status_text(issuable)
          issuable.open? ? 'Open' : 'Closed'
        end

        def project
          resource.project
        end

        def author
          resource.author
        end

        def fields
          [
            {
              title: "Assignee",
              value: resource.assignees.any? ? resource.assignees.first.name : "_None_",
              short: true
            },
            {
              title: "Milestone",
              value: resource.milestone ? resource.milestone.title : "_None_",
              short: true
            },
            {
              title: "Labels",
              value: resource.labels.any? ? resource.label_names.join(', ') : "_None_",
              short: true
            }
          ]
        end

        private

        attr_reader :resource

        alias_method :issue, :resource
      end
    end
  end
end

Gitlab::SlashCommands::Presenters::IssueBase.prepend_mod_with('Gitlab::SlashCommands::Presenters::IssueBase')
