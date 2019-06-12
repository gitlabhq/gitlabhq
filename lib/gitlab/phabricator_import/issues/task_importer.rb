# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Issues
      class TaskImporter
        def initialize(project, task)
          @project, @task = project, task
        end

        def execute
          # TODO: get the user from the project namespace from the username loaded by Phab-id
          # https://gitlab.com/gitlab-org/gitlab-ce/issues/60565
          issue.author = User.ghost

          # TODO: Reformat the description with attachments, escaping accidental
          # links and add attachments
          # https://gitlab.com/gitlab-org/gitlab-ce/issues/60603
          issue.assign_attributes(task.issue_attributes)

          save!

          issue
        end

        private

        attr_reader :project, :task

        def save!
          # Just avoiding an extra redis call, we've already updated the expiry
          # when reading the id from the map
          was_persisted = issue.persisted?

          issue.save! if issue.changed?

          object_map.set_gitlab_model(issue, task.phabricator_id) unless was_persisted
        end

        def issue
          @issue ||= find_issue_by_phabricator_id(task.phabricator_id) ||
            project.issues.new
        end

        def find_issue_by_phabricator_id(phabricator_id)
          object_map.get_gitlab_model(phabricator_id)
        end

        def object_map
          Gitlab::PhabricatorImport::Cache::Map.new(project)
        end
      end
    end
  end
end
