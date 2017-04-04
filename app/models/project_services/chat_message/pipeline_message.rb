module ChatMessage
  class PipelineMessage < BaseMessage
    attr_reader :ref_type
    attr_reader :ref
    attr_reader :status
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :user_name
    attr_reader :duration
    attr_reader :pipeline_id
    attr_reader :user_avatar

    def initialize(data)
      pipeline_attributes = data[:object_attributes]
      @ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
      @ref = pipeline_attributes[:ref]
      @status = pipeline_attributes[:status]
      @duration = pipeline_attributes[:duration]
      @pipeline_id = pipeline_attributes[:id]

      super(data)

      @project_name = data[:project][:path_with_namespace]
      @project_url = data[:project][:web_url]
      @user_name = (data[:user] && data[:user][:name]) || 'API'
      @user_avatar = data[:user][:avatar_url] || ''
    end

    def pretext
      ''
    end

    def fallback
      format(message)
    end

    def activity
      MicrosoftTeams::Activity.new(
        "Pipeline #{pipeline_link} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status}",
        "to: #{project_link}",
        "in #{duration} #{time_measure}",
        user_avatar
      ).to_json
    end

    def attachments
      markdown_format ? message : [{ text: format(message), color: attachment_color }]
    end

    private

    def message
      "#{project_link}: Pipeline #{pipeline_link} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status} in #{duration} #{time_measure}"
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

    def time_measure
      'second'.pluralize(duration)
    end
  end
end
