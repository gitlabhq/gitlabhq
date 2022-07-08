# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedLabel
          def initialize(project, user_id)
            @project = project
            @user_id = user_id
          end

          # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
          def execute(issue_event)
            create_event(issue_event)
          end

          private

          attr_reader :project, :user_id

          def create_event(issue_event)
            ResourceLabelEvent.create!(
              issue_id: issue_event.issue_db_id,
              user_id: user_id,
              label_id: label_finder.id_for(issue_event.label_title),
              action: action(issue_event.event),
              created_at: issue_event.created_at
            )
          end

          def label_finder
            Gitlab::GithubImport::LabelFinder.new(project)
          end

          def action(event_type)
            event_type == 'unlabeled' ? 'remove' : 'add'
          end
        end
      end
    end
  end
end
