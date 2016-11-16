class SlackService
  class PipelineMessage < BaseMessage
    attr_reader :ref_type, :ref, :status, :project_name, :project_url,
                :user_name, :duration, :pipeline_id

    def initialize(data)
      pipeline_attributes = data[:object_attributes]
      @ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
      @ref = pipeline_attributes[:ref]
      @status = pipeline_attributes[:status]
      @duration = pipeline_attributes[:duration]
      @pipeline_id = pipeline_attributes[:id]

      @project_name = data[:project][:path_with_namespace]
      @project_url = data[:project][:web_url]
      @user_name = data[:user] && data[:user][:name]
    end

    def pretext
      ''
    end

    def fallback
      format(message)
    end

    def attachments
      [{ text: format(message), color: attachment_color }]
    end

    private

    def message
      "#{project_link}: Pipeline #{pipeline_link} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status} in #{duration} #{'second'.pluralize(duration)}"
    end

    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def humanized_status
      case status
      when 'success'
        'passed'
      else
        status
      end
    end

    def attachment_color
      if status == 'success'
        'good'
      else
        'danger'
      end
    end

    def branch_url
      "#{project_url}/commits/#{ref}"
    end

    def branch_link
      "[#{ref}](#{branch_url})"
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def pipeline_url
      "#{project_url}/pipelines/#{pipeline_id}"
    end

    def pipeline_link
      "[##{pipeline_id}](#{pipeline_url})"
    end
  end
end
