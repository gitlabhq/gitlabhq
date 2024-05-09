# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class Inline < BaseNoteDiffImporter
          def execute(comment)
            log_info(
              import_stage: 'import_inline_comments',
              message: 'starting',
              iid: merge_request.iid,
              comment_id: comment[:id]
            )

            position = build_position(merge_request, comment)
            parent = create_diff_note(merge_request, comment, position)

            return unless parent&.persisted?

            discussion_id = parent.discussion_id

            comment[:comments].each do |reply|
              create_diff_note(merge_request, reply, position, discussion_id)
            end

            log_info(
              import_stage: 'import_inline_comments',
              message: 'finished',
              iid: merge_request.iid,
              comment_id: comment[:id]
            )
          end
        end
      end
    end
  end
end
