# frozen_string_literal: true
require 'spamcheck'

module Gitlab
  module Spamcheck
    class Client
      include ::Spam::SpamConstants
      DEFAULT_TIMEOUT_SECS = 2

      VERDICT_MAPPING = {
        ::Spamcheck::SpamVerdict::Verdict::ALLOW => ALLOW,
        ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW => CONDITIONAL_ALLOW,
        ::Spamcheck::SpamVerdict::Verdict::DISALLOW => DISALLOW,
        ::Spamcheck::SpamVerdict::Verdict::BLOCK => BLOCK_USER,
        ::Spamcheck::SpamVerdict::Verdict::NOOP => NOOP
      }.freeze

      ACTION_MAPPING = {
        create: ::Spamcheck::Action::CREATE,
        update: ::Spamcheck::Action::UPDATE
      }.freeze

      def initialize
        @endpoint_url = Gitlab::CurrentSettings.current_application_settings.spam_check_endpoint_url

        # remove the `grpc://` as it's only useful to ensure we're expecting to
        # connect with Spamcheck
        @endpoint_url = @endpoint_url.gsub(%r(^grpc:\/\/), '')

        @creds =
          if Rails.env.development? || Rails.env.test?
            :this_channel_is_insecure
          else
            GRPC::Core::ChannelCredentials.new
          end
      end

      def issue_spam?(spam_issue:, user:, context: {})
        issue = build_issue_protobuf(issue: spam_issue, user: user, context: context)

        response = grpc_client.check_for_spam_issue(issue,
                                              metadata: { 'authorization' =>
                                                           Gitlab::CurrentSettings.spam_check_api_key })
        verdict = convert_verdict_to_gitlab_constant(response.verdict)
        [verdict, response.extra_attributes.to_h, response.error]
      end

      private

      def convert_verdict_to_gitlab_constant(verdict)
        VERDICT_MAPPING.fetch(::Spamcheck::SpamVerdict::Verdict.resolve(verdict), verdict)
      end

      def build_issue_protobuf(issue:, user:, context:)
        issue_pb = ::Spamcheck::Issue.new
        issue_pb.title = issue.spam_title || ''
        issue_pb.description = issue.spam_description || ''
        issue_pb.created_at = convert_to_pb_timestamp(issue.created_at) if issue.created_at
        issue_pb.updated_at = convert_to_pb_timestamp(issue.updated_at) if issue.updated_at
        issue_pb.user_in_project = user.authorized_project?(issue.project)
        issue_pb.project = build_project_protobuf(issue)
        issue_pb.action = ACTION_MAPPING.fetch(context.fetch(:action)) if context.has_key?(:action)
        issue_pb.user = build_user_protobuf(user)
        issue_pb
      end

      def build_user_protobuf(user)
        user_pb = ::Spamcheck::User.new
        user_pb.username = user.username
        user_pb.org = user.organization || ''
        user_pb.created_at = convert_to_pb_timestamp(user.created_at)

        user_pb.emails << build_email(user.email, user.confirmed?)

        user.emails.each do |email|
          user_pb.emails << build_email(email.email, email.confirmed?)
        end

        user_pb
      end

      def build_email(email, verified)
        email_pb = ::Spamcheck::User::Email.new
        email_pb.email = email
        email_pb.verified = verified
        email_pb
      end

      def build_project_protobuf(issue)
        project_pb = ::Spamcheck::Project.new
        project_pb.project_id = issue.project_id
        project_pb.project_path = issue.project.full_path
        project_pb
      end

      def convert_to_pb_timestamp(ar_timestamp)
        Google::Protobuf::Timestamp.new(seconds: ar_timestamp.to_time.to_i,
                                        nanos: ar_timestamp.to_time.nsec)
      end

      def grpc_client
        @grpc_client ||= ::Spamcheck::SpamcheckService::Stub.new(@endpoint_url, @creds,
                                                        interceptors: interceptors,
                                                        timeout: DEFAULT_TIMEOUT_SECS)
      end

      def interceptors
        [Labkit::Correlation::GRPC::ClientInterceptor.instance]
      end
    end
  end
end
