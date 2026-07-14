# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

# Handles comment creation emails when sent/forwarded by an authorized
# user. Attachments are allowed. Quoted material is _not_ stripped, just like
# create issue emails
# Supports these formats:
#   incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue-34@incoming.gitlab.com
module Gitlab
  module Email
    module Handler
      class CreateNoteOnIssuableHandler < BaseHandler
        include ReplyProcessing

        def self.gem_handler
          :create_note_on_issuable
        end

        def issuable_iid
          return unless identification

          identification[:issuable_iid]
        end

        def execute
          raise ProjectNotFound unless project

          log_email_handler
          validate_permission!(:create_note)

          raise NoteableNotFoundError unless noteable
          raise EmptyEmailError if message_including_reply.blank?

          verify_record!(
            record: create_note,
            invalid_exception: InvalidNoteError,
            record_name: 'comment')
        end

        def metrics_event
          :receive_email_create_note_issuable
        end

        def noteable
          return unless issuable_iid

          @noteable ||= project&.issues&.find_by_iid(issuable_iid)
        end

        private

        def parent_namespace
          project.project_namespace
        end

        def additional_log_data
          { Labkit::Fields::GL_PROJECT_ID => project.id }
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def create_note
          Notes::CreateService.new(project, author, note_params).execute
        end

        def note_params
          {
            noteable_type: noteable.class.to_s,
            noteable_id: noteable.id,
            note: message_including_reply
          }
        end
      end
    end
  end
end
