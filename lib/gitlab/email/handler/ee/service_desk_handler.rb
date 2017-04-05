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
            raise ProjectNotFound if project.nil?

            create_issue!
            send_thank_you_email! if from_address
          end

          private

          def service_desk_key
            @service_desk_key ||=
              begin
                mail_key =~ /\Aservice_desk[+](\w+)\z/
                $1
              end
          end

          def project
            return @project if instance_variable_defined?(:@project)

            @project = Project.find_by(
              service_desk_enabled: true,
              service_desk_mail_key: service_desk_key
            )
          end

          def create_issue!
            # NB: the support bot is specifically forbidden
            # from mentioning any entities, or from using
            # slash commands.
            @issue = Issues::CreateService.new(
              project,
              User.support_bot,
              title: issue_title,
              description: message,
              confidential: true,
              service_desk_reply_to: from_address,
            ).execute

            raise InvalidIssueError unless @issue.persisted?
          end

          def send_thank_you_email!
            Notify.service_desk_thank_you_email(@issue.id).deliver_later!
          end

          def from_address
            (mail.reply_to || []).first || mail.sender || mail.from.first
          end

          def issue_title
            from = "(from #{from_address})" if from_address

            "Service Desk #{from}: #{mail.subject}"
          end
        end
      end
    end
  end
end
