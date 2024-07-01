# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class IssueNotesImporter
        include ParallelScheduling

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          @ref_converter = Gitlab::BitbucketImport::RefConverter.new(project)
          @mentions_converter = Gitlab::Import::MentionsConverter.new('bitbucket', project)
          @object = hash.with_indifferent_access
        end

        def execute
          log_info(import_stage: 'import_issue_notes', message: 'starting', iid: object[:iid])

          issue = project.issues.find_by(iid: object[:iid]) # rubocop: disable CodeReuse/ActiveRecord

          if issue
            client.issue_comments(project.import_source, issue.iid).each do |comment|
              next unless comment.note.present?

              issue.notes.create!(
                project: project,
                note: comment_note(comment),
                author_id: user_finder.gitlab_user_id(project, comment.author),
                created_at: comment.created_at,
                updated_at: comment.updated_at,
                imported_from: ::Import::SOURCE_BITBUCKET
              )
            end
          end

          log_info(import_stage: 'import_issue_notes', message: 'finished', iid: object[:iid])
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :object, :project, :formatter, :user_finder, :ref_converter, :mentions_converter

        def comment_note(comment)
          note = ''
          note += formatter.author_line(comment.author_nickname) unless user_finder.find_user_id(comment.author)
          note += ref_converter.convert_note(comment.note)

          mentions_converter.convert(note)
        end
      end
    end
  end
end
