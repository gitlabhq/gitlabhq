# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestReviewImporter
        def initialize(review, project, client)
          @review = review
          @project = project
          @client = client
          @merge_request = project.merge_requests.find_by_id(review.merge_request_id)
        end

        def execute
          user_finder = GithubImport::UserFinder.new(project, client)
          gitlab_user_id = user_finder.user_id_for(review.author)

          if gitlab_user_id
            add_review_note!(gitlab_user_id)
            add_approval!(gitlab_user_id)
          else
            add_complementary_review_note!(project.creator_id)
          end
        end

        private

        attr_reader :review, :merge_request, :project, :client

        def add_review_note!(author_id)
          return if review.note.empty?

          add_note!(author_id, review_note_content)
        end

        def add_complementary_review_note!(author_id)
          return if review.note.empty? && !review.approval?

          note_body = MarkdownText.format(
            review_note_content,
            review.author
          )

          add_note!(author_id, note_body)
        end

        def review_note_content
          header = "**Review:** #{review.review_type.humanize}"

          if review.note.present?
            "#{header}\n\n#{review.note}"
          else
            header
          end
        end

        def add_note!(author_id, note)
          note = Note.new(note_attributes(author_id, note))

          note.save!
        end

        def note_attributes(author_id, note, extra = {})
          {
            importing: true,
            noteable_id: merge_request.id,
            noteable_type: 'MergeRequest',
            project_id: project.id,
            author_id: author_id,
            note: note,
            system: false,
            created_at: submitted_at,
            updated_at: submitted_at
          }.merge(extra)
        end

        def add_approval!(user_id)
          return unless review.review_type == 'APPROVED'

          approval_attribues = {
            merge_request_id: merge_request.id,
            user_id: user_id,
            created_at: submitted_at,
            updated_at: submitted_at
          }

          result = ::Approval.insert(
            approval_attribues,
            returning: [:id],
            unique_by: [:user_id, :merge_request_id]
          )

          if result.rows.present?
            add_approval_system_note!(user_id)
          end
        end

        def add_approval_system_note!(user_id)
          attributes = note_attributes(
            user_id,
            'approved this merge request',
            system: true,
            system_note_metadata: SystemNoteMetadata.new(action: 'approved')
          )

          Note.create!(attributes)
        end

        def submitted_at
          @submitted_at ||= (review.submitted_at || merge_request.updated_at)
        end
      end
    end
  end
end
