# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class ReviewImporter
          include ::Gitlab::Import::MergeRequestHelpers
          include Gitlab::GithubImport::PushPlaceholderReferences

          # review - An instance of `Gitlab::GithubImport::Representation::PullRequestReview`
          # project - An instance of `Project`
          # client - An instance of `Gitlab::GithubImport::Client`
          def initialize(review, project, client)
            @review = review
            @project = project
            @client = client
            @merge_request = project.merge_requests.find_by_iid(review.merge_request_iid)
            @user_finder = GithubImport::UserFinder.new(project, client)
            @mapper = Gitlab::GithubImport::ContributionsMapper.new(project)
          end

          def execute(options = {})
            options = { add_reviewer: true }.merge(options)

            user_finder = GithubImport::UserFinder.new(project, client)

            gitlab_user_id = user_finder.user_id_for(review.author)

            if gitlab_user_id
              add_review_note!(gitlab_user_id)
              add_approval!(gitlab_user_id)
              add_reviewer!(gitlab_user_id) if options[:add_reviewer]
            else
              # TODO this method and this if/else can be removed when `github_user_mapping` flag is removed
              # because there will always be a gitlab_user_id when using placeholder users.
              add_complementary_review_note!(project.creator_id)
            end
          end

          private

          attr_reader :review, :merge_request, :project, :client, :mapper, :user_finder

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

            return unless mapper.user_mapping_enabled?

            push_with_record(note, :author_id, review.author&.id, mapper.user_mapper)
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
              updated_at: submitted_at,
              imported_from: ::Import::SOURCE_GITHUB
            }.merge(extra)
          end

          def add_approval!(user_id)
            return unless review.review_type == 'APPROVED'

            approval, approval_system_note = create_approval!(project.id, merge_request.id, user_id, submitted_at)

            return unless mapper.user_mapping_enabled? && approval

            push_with_record(approval, :user_id, review.author&.id, mapper.user_mapper)
            push_with_record(approval_system_note, :author_id, review.author&.id, mapper.user_mapper)
          end

          def add_reviewer!(user_id)
            reviewer = create_reviewer!(merge_request.id, user_id, submitted_at)

            return unless mapper.user_mapping_enabled? && reviewer

            push_with_record(reviewer, :user_id, review.author&.id, mapper.user_mapper)
          end

          def submitted_at
            @submitted_at ||= (review.submitted_at || merge_request.updated_at)
          end
        end
      end
    end
  end
end
