# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class BaseNoteDiffImporter < BaseImporter
          PARENT_COMMENT_CONTEXT_LENGTH = 80

          def build_position(merge_request, pr_comment)
            params = {
              diff_refs: merge_request.diff_refs,
              old_path: pr_comment[:file_path],
              new_path: pr_comment[:file_path],
              old_line: pr_comment[:old_pos],
              new_line: pr_comment[:new_pos]
            }

            Gitlab::Diff::Position.new(params)
          end

          def create_diff_note(merge_request, comment, position, discussion_id = nil)
            attributes = pull_request_comment_attributes(comment)
            attributes.merge!(position: position, type: 'DiffNote')
            attributes[:discussion_id] = discussion_id if discussion_id

            note = merge_request.notes.build(attributes)

            if note.valid?
              note.save
              push_reference(project, note, :author_id, comment[:author_username])

              return note
            end

            log_info(
              import_stage: 'create_diff_note',
              message: 'creating standalone fallback for DiffNote',
              iid: merge_request.iid,
              comment_id: comment[:id]
            )

            # Bitbucket Server supports the ability to comment on any line, not just the
            # line in the diff. If we can't add the note as a DiffNote, fallback to creating
            # a regular note.
            create_basic_fallback_note(merge_request, comment, position)
          rescue StandardError => e
            Gitlab::ErrorTracking.log_exception(
              e,
              import_stage: 'create_diff_note', comment_id: comment[:id], error: e.message
            )

            nil
          end

          def pull_request_comment_attributes(comment)
            author = author(comment)
            note = ''

            unless author
              author = project.creator_id
              note = "*By #{comment[:author_username]} (#{comment[:author_email]})*\n\n"
            end

            note +=
              # Provide some context for replying
              if comment[:parent_comment_note]
                parent_comment_note = comment[:parent_comment_note].truncate(80, omission: ' ...')

                "> #{parent_comment_note}\n\n#{comment[:note]}"
              else
                comment[:note]
              end

            {
              project: project,
              note: wrap_mentions_in_backticks(note),
              author_id: author,
              created_at: comment[:created_at],
              updated_at: comment[:updated_at]
            }
          end

          def author(comment)
            if user_mapping_enabled?(project)
              user_finder.uid(
                username: comment[:author_username],
                display_name: comment[:author_name]
              )
            else
              user_finder.uid(comment)
            end
          end

          def create_basic_fallback_note(merge_request, comment, position)
            attributes = pull_request_comment_attributes(comment)
            note_text = "*Comment on"

            note_text += " #{position.old_path}:#{position.old_line} -->" if position.old_line
            note_text += " #{position.new_path}:#{position.new_line}" if position.new_line
            note_text += "*\n\n#{wrap_mentions_in_backticks(comment[:note])}"

            attributes[:note] = note_text

            note = merge_request.notes.create!(attributes)
            push_reference(project, note, :author_id, comment[:author_username])
            note
          end
        end
      end
    end
  end
end
