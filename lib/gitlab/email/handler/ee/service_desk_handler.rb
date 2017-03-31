module Gitlab
  module Email
    module Handler
      module EE
        class ServiceDeskHandler < BaseHandler
          include ReplyProcessing

          def can_handle?
            Gitlab::EE::ServiceDesk.enabled? && service_desk_key.present?
          end

          def execute
            raise EmailUnparsableError if from_address.blank?
            raise ProjectNotFound if project.nil?

            create_issue!
            send_thank_you_email!
          end

          private

          def service_desk_key
            @service_desk_key ||=
              begin
                mail_key =~ /\Aservice-desk[+](\w+)\z/
                $1
              end
          end

          def project
            return @project if instance_variable_defined?(:@project)

            @project = Project.where(
              service_desk_enabled: true,
              service_desk_mail_key: service_desk_key
            ).first
          end

          def create_issue!
            # NB: the support bot is specifically forbidden
            # from mentioning any entities, or from using
            # slash commands.
            @issue = Issues::CreateService.new(
              project,
              User.support_bot,
              title: mail.subject,
              description: message,
              confidential: true,
              service_desk_reply_to: from_address,
            ).execute

            raise InvalidIssueError unless @issue.persisted?
          end

          def send_thank_you_email!
            Notify.service_desk_thank_you_email(@issue.id)
          end

          def from_address
            (mail.reply_to || []).first || mail.sender || mail.from.first
          end
        end
      end
    end
  end
end
