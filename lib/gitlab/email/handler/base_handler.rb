module Gitlab
  module Email
    module Handler
      class BaseHandler
        attr_reader :mail, :mail_key

        def initialize(mail, mail_key)
          @mail = mail
          @mail_key = mail_key
        end

        def message
          @message ||= process_message
        end

        def author
          raise NotImplementedError
        end

        def project
          raise NotImplementedError
        end

        private

        def validate_permission!(permission)
          raise UserNotFoundError unless author
          raise UserBlockedError if author.blocked?
          raise ProjectNotFound unless author.can?(:read_project, project)
          raise UserNotAuthorizedError unless author.can?(permission, project)
        end

        def process_message
          add_attachments(ReplyParser.new(mail).execute.strip)
        end

        def add_attachments(reply)
          attachments = Email::AttachmentUploader.new(mail).execute(project)

          reply + attachments.map do |link|
            "\n\n#{link[:markdown]}"
          end.join
        end

        def verify_record!(record, exception, name)
          return if record.persisted?

          error_title =
            "The #{name} could not be created for the following reasons:"

          msg = error_title + record.errors.full_messages.map do |error|
            "\n\n- #{error}"
          end.join

          raise exception, msg
        end
      end
    end
  end
end
