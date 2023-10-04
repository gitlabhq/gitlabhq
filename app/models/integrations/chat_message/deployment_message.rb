# frozen_string_literal: true

module Integrations
  module ChatMessage
    class DeploymentMessage < BaseMessage
      attr_reader :commit_title
      attr_reader :commit_url
      attr_reader :deployable_id
      attr_reader :deployable_url
      attr_reader :environment
      attr_reader :short_sha
      attr_reader :status
      attr_reader :user_url

      def initialize(data)
        super

        @commit_title = data[:commit_title]
        @commit_url = data[:commit_url]
        @deployable_id = data[:deployable_id]
        @deployable_url = data[:deployable_url]
        @environment = data[:environment]
        @short_sha = data[:short_sha]
        @status = data[:status]
        @user_url = data[:user_url]
      end

      def attachments
        return description_message if markdown

        [{
          text: format(description_message),
          color: attachment_color
        }]
      end

      def activity
        {}
      end

      def attachment_color
        case status
        when 'success'
          'good'
        when 'canceled'
          'warning'
        when 'failed'
          'danger'
        else
          '#334455'
        end
      end

      private

      def message
        if running?
          "Starting deploy to #{strip_markup(environment)}"
        else
          "Deploy to #{strip_markup(environment)} #{humanized_status}"
        end
      end

      def project_link
        link(project_name, project_url)
      end

      def deployment_link
        link("##{deployable_id}", deployable_url)
      end

      def user_link
        link(user_combined_name, user_url)
      end

      def commit_link
        link(short_sha, commit_url)
      end

      def humanized_status
        status == 'success' ? 'succeeded' : status
      end

      def running?
        status == 'running'
      end

      def description_message
        "#{project_link} with job #{deployment_link} by #{user_link}\n#{commit_link}: #{strip_markup(commit_title)}"
      end
    end
  end
end
