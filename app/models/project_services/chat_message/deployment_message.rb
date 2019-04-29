# frozen_string_literal: true

module ChatMessage
  class DeploymentMessage < BaseMessage
    attr_reader :commit_url
    attr_reader :deployable_id
    attr_reader :deployable_url
    attr_reader :environment
    attr_reader :short_sha
    attr_reader :status

    def initialize(data)
      super

      @commit_url = data[:commit_url]
      @deployable_id = data[:deployable_id]
      @deployable_url = data[:deployable_url]
      @environment = data[:environment]
      @short_sha = data[:short_sha]
      @status = data[:status]
    end

    def attachments
      [{
        text: "#{project_link}\n#{deployment_link}, SHA #{commit_link}, by #{user_combined_name}",
        color: color
      }]
    end

    def activity
      {}
    end

    private

    def message
      "Deploy to #{environment} #{humanized_status}"
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
      link("Job ##{deployable_id}", deployable_url)
    end

    def commit_link
      link(short_sha, commit_url)
    end

    def humanized_status
      status == 'success' ? 'succeeded' : status
    end
  end
end
