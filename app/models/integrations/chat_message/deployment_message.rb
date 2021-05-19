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
        [{
          text: "#{project_link} with job #{deployment_link} by #{user_link}\n#{commit_link}: #{commit_title}",
          color: color
        }]
      end

      def activity
        {}
      end

      private

      def message
        if running?
          "Starting deploy to #{environment}"
        else
          "Deploy to #{environment} #{humanized_status}"
        end
      end

      def color
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
    end
  end
end
