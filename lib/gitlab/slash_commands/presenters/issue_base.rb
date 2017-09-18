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

        # rubocop:disable Cop/ModuleWithInstanceVariables
        def project
          @resource.project
        end

        # rubocop:disable Cop/ModuleWithInstanceVariables
        def author
          @resource.author
        end

        # rubocop:disable Cop/ModuleWithInstanceVariables
        def fields
          [
            {
              title: "Assignee",
              value: @resource.assignees.any? ? @resource.assignees.first.name : "_None_",
              short: true
            },
            {
              title: "Milestone",
              value: @resource.milestone ? @resource.milestone.title : "_None_",
              short: true
            },
            {
              title: "Labels",
              value: @resource.labels.any? ? @resource.label_names.join(', ') : "_None_",
              short: true
            }
          ]
        end
      end
    end
  end
end
