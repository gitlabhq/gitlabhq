# frozen_string_literal: true

# handles service desk issue creation emails with these formats:
#   incoming+gitlab-org-gitlab-ce-20-issue-@incoming.gitlab.com
#   incoming+gitlab-org/gitlab-ce@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      class ServiceDeskHandler < BaseHandler
        include ReplyProcessing
        include Gitlab::Utils::StrongMemoize

        HANDLER_REGEX        = /\A#{HANDLER_ACTION_BASE_REGEX}-issue-\z/
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\z/
        PROJECT_KEY_PATTERN  = /\A(?<slug>.+)-(?<key>[a-z0-9_]+)\z/

        def initialize(mail, mail_key, service_desk_key: nil)
          if service_desk_key
            mail_key ||= service_desk_key
            @service_desk_key = service_desk_key
          end

          super(mail, mail_key)

          match_project_slug || match_legacy_project_slug
        end

        def can_handle?
          ::ServiceDesk.supported? && (project_id || can_handle_legacy_format? || service_desk_key)
        end

        def execute
          raise ProjectNotFound if project.nil?

          # Verification emails should never create issues
          return if handled_custom_email_address_verification?

          create_issue_or_note

          if from_address
            add_email_participants
            send_thank_you_email unless reply_email?
          end
        end

        def match_project_slug
          return if mail_key&.include?('/')
          return unless matched = HANDLER_REGEX.match(mail_key.to_s)

          @project_slug = matched[:project_slug]
          @project_id   = matched[:project_id]&.to_i
        end

        def match_legacy_project_slug
          return unless matched = HANDLER_REGEX_LEGACY.match(mail_key.to_s)

          @project_path = matched[:project_path]
        end

        def metrics_event
          :receive_email_service_desk
        end

        def project
          strong_memoize(:project) do
            project_record = super
            project_record ||= project_from_key if service_desk_key
            project_record && ::ServiceDesk.enabled?(project_record) ? project_record : nil
          end
        end

        private

        attr_reader :project_id, :project_path, :service_desk_key

        def contains_custom_email_address_verification_subaddress?
          return false unless to_address.present?

          # Verification email only has one recipient
          to_address.include?(ServiceDeskSetting::CUSTOM_EMAIL_VERIFICATION_SUBADDRESS)
        end

        def handled_custom_email_address_verification?
          return false unless contains_custom_email_address_verification_subaddress?

          ::ServiceDesk::CustomEmailVerifications::UpdateService.new(
            project: project,
            current_user: nil,
            params: {
              mail: mail
            }
          ).execute

          true
        end

        def project_from_key
          return unless match = service_desk_key.match(PROJECT_KEY_PATTERN)

          Project.with_service_desk_key(match[:key]).find do |project|
            valid_project_key?(project, match[:slug])
          end
        end

        def valid_project_key?(project, slug)
          project.present? && slug == project.full_path_slug
        end

        def create_issue_or_note
          if reply_email?
            create_note_from_reply_email
          else
            create_issue!
          end
        end

        def create_issue!
          result = ::Issues::CreateService.new(
            container: project,
            current_user: Users::Internal.support_bot,
            params: {
              title: mail.subject,
              description: message_including_template,
              confidential: ticket_confidential?,
              external_author: from_address,
              extra_params: {
                cc: mail.cc
              }
            },
            perform_spam_check: false
          ).execute

          raise InvalidIssueError if result.error?

          @issue = result[:issue]

          begin
            ::Issue::Email.create!(issue: @issue, email_message_id: mail.message_id)
          rescue StandardError => e
            Gitlab::ErrorTracking.log_exception(e)
          end

          if service_desk_setting&.issue_template_missing?
            create_template_not_found_note
          end
        end

        def issue_from_reply_to
          strong_memoize(:issue_from_reply_to) do
            next unless mail.in_reply_to

            Issue::Email.find_by_email_message_id(mail.in_reply_to)&.issue
          end
        end

        def reply_email?
          issue_from_reply_to.present?
        end

        def create_note_from_reply_email
          @issue = issue_from_reply_to

          create_note(message_including_reply)
        end

        def send_thank_you_email
          Notify.service_desk_thank_you_email(@issue.id).deliver_later
          Gitlab::Metrics::BackgroundTransaction.current&.add_event(:service_desk_thank_you_email)
        end

        def message_including_template
          description = message_including_reply_or_only_quotes
          template_content = service_desk_setting&.issue_template_content

          if template_content.present?
            description += "  \n" + template_content
          end

          description
        end

        def service_desk_setting
          strong_memoize(:service_desk_setting) do
            project.service_desk_setting
          end
        end

        def create_template_not_found_note
          issue_template_key = service_desk_setting&.issue_template_key

          warning_note = <<-MD.strip_heredoc
            WARNING: The template file #{issue_template_key}.md used for service desk issues is empty or could not be found.
            Please check service desk settings and update the file to be used.
          MD

          create_note(warning_note)
        end

        def create_note(note)
          ::Notes::CreateService.new(
            project,
            Users::Internal.support_bot,
            noteable: @issue,
            note: note
          ).execute
        end

        def from_address
          (mail.reply_to || []).first || mail.from.first || mail.sender
        end

        def to_address
          mail.to&.first
        end
        strong_memoize_attr :to_address

        def cc_addresses
          mail.cc || []
        end

        def can_handle_legacy_format?
          project_path && project_path.include?('/') && mail_key.exclude?('+')
        end

        def author
          Users::Internal.support_bot
        end

        def add_email_participants
          return if reply_email? && !Feature.enabled?(:issue_email_participants, @issue.project)

          # Migrate this to ::IssueEmailParticipants::CreateService once the
          # feature flag issue_email_participants has been enabled globally
          # or removed: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137147#note_1652104416
          @issue.issue_email_participants.create(email: from_address)

          add_external_participants_from_cc
        end

        def add_external_participants_from_cc
          return if project.service_desk_setting.nil?
          return unless project.service_desk_setting.add_external_participants_from_cc?

          ::IssueEmailParticipants::CreateService.new(
            target: @issue,
            current_user: Users::Internal.support_bot,
            emails: cc_addresses.excluding(service_desk_addresses)
          ).execute
        end

        def service_desk_addresses
          ::ServiceDesk::Emails.new(project).all_addresses
        end
        strong_memoize_attr :service_desk_addresses

        def ticket_confidential?
          return true if service_desk_setting.nil?

          service_desk_setting.tickets_confidential_by_default?
        end
      end
    end
  end
end
