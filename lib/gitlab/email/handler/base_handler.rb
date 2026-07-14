# frozen_string_literal: true

module Gitlab
  module Email
    module Handler
      class BaseHandler
        include ::Gitlab::Loggable
        include ::Gitlab::Utils::StrongMemoize

        attr_reader :mail, :mail_key

        # The gitlab-email_handler matcher name for this handler. Subclasses
        # that delegate parsing to the gem override this.
        def self.gem_handler
          nil
        end

        def initialize(mail, mail_key)
          @mail = mail
          @mail_key = mail_key
        end

        # Parses the mail key using the gitlab-email_handler gem matcher for
        # this handler. Returns a Gitlab::EmailHandler::Identification or nil.
        # Subclasses declare their matcher via `gem_handler`.
        def identification
          return unless self.class.gem_handler

          ::Gitlab::EmailHandler::Identifier.for_handler(self.class.gem_handler, mail_key.to_s)
        end
        strong_memoize_attr :identification

        # A handler can handle the mail when its gem matcher successfully
        # identifies the key. Handlers with different criteria override this.
        def can_handle?
          !identification.nil?
        end

        def execute
          raise NotImplementedError
        end

        def metrics_params
          { handler: self.class.name }
        end

        # Each handler should use it's own metric event.  Otherwise there
        # is a possibility that within the same Sidekiq process, that same
        # event with different metrics_params will cause Prometheus to
        # throw an error
        def metrics_event
          raise NotImplementedError
        end

        private

        def additional_log_data
          {}
        end

        def log_email_handler
          logger.info(
            build_structured_payload_labkit(
              **additional_log_data.merge(
                Labkit::Fields::LOG_MESSAGE => 'Incoming email handler execution',
                Labkit::Fields::GL_NAMESPACE_ID => parent_namespace.id,
                Labkit::Fields::GL_ROOT_NAMESPACE_ID => parent_namespace.root_ancestor.id
              )
            )
          )
        end

        def logger
          @logger ||= ::Gitlab::AppJsonLogger.build
        end

        def reopen_issue_on_external_participant_note(noteable:, author:, project:, support_bot:)
          return unless noteable.respond_to?(:closed?)
          return unless noteable.closed?
          return unless author.support_bot?
          return unless project&.service_desk_setting&.reopen_issue_on_external_participant_note?

          ::Notes::CreateService.new(
            project,
            support_bot,
            noteable: noteable,
            note: build_reopen_message(noteable),
            confidential: true
          ).execute
        end

        def build_reopen_message(noteable)
          translated_text = s_(
            "ServiceDesk|This issue has been reopened because it received a new comment from an external participant."
          )

          "#{assignees_references(noteable)} :wave: #{translated_text}\n/reopen".lstrip
        end

        def assignees_references(noteable)
          return unless noteable.assignees.any?

          noteable.assignees.map(&:to_reference).join(' ')
        end

        def from_address
          (mail.reply_to || []).first || mail.from.first || mail.sender
        end
      end
    end
  end
end
