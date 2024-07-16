# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class IssueImporter
        include Loggable
        include ErrorTracking

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          @mentions_converter = Gitlab::Import::MentionsConverter.new('bitbucket', project)
          @object = hash.with_indifferent_access
        end

        def execute
          log_info(import_stage: 'import_issue', message: 'starting', iid: object[:iid])

          milestone = object[:milestone] ? project.milestones.find_or_create_by(title: object[:milestone]) : nil # rubocop: disable CodeReuse/ActiveRecord

          attributes = {
            iid: object[:iid],
            title: object[:title],
            description: description,
            state_id: Issue.available_states[object[:state]],
            author_id: author_id,
            assignee_ids: [author_id],
            namespace_id: project.project_namespace_id,
            milestone: milestone,
            work_item_type_id: object[:issue_type_id],
            label_ids: [object[:label_id]].compact,
            created_at: object[:created_at],
            updated_at: object[:updated_at],
            imported_from: ::Import::SOURCE_BITBUCKET
          }

          project.issues.create!(attributes)

          metrics.issues_counter.increment

          log_info(import_stage: 'import_issue', message: 'finished', iid: object[:iid])
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :object, :project, :formatter, :user_finder, :mentions_converter

        def description
          description = ''
          description += author_line
          description += object[:description] if object[:description]

          mentions_converter.convert(description)
        end

        def author_line
          return '' if find_user_id

          formatter.author_line(object[:author_nickname])
        end

        def find_user_id
          user_finder.find_user_id(object[:author])
        end

        def author_id
          user_finder.gitlab_user_id(project, object[:author])
        end
      end
    end
  end
end
