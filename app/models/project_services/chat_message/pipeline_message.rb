module ChatMessage
  class PipelineMessage < BaseMessage
    attr_reader :ref_type
    attr_reader :ref
    attr_reader :status
    attr_reader :duration
    attr_reader :pipeline_id

    def initialize(data)
      super

      @user_name = data.dig(:user, :username) || 'API'

      pipeline_attributes = data[:object_attributes]
      @ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
      @ref = pipeline_attributes[:ref]
      @status = pipeline_attributes[:status]
      @duration = pipeline_attributes[:duration].to_i
      @pipeline_id = pipeline_attributes[:id]
    end

    def pretext
      ''
    end

    def fallback
      format(message)
    end

    def attachments
      return message if markdown

      [{ text: format(message), color: attachment_color }]
    end

    def activity
      {
        title: "Pipeline #{pipeline_link} of #{ref_type} #{branch_link} by #{user_combined_name} #{humanized_status}",
        subtitle: "in #{project_link}",
        text: "in #{pretty_duration(duration)}",
        image: user_avatar || ''
      }
    end

    private

    def message
      "#{project_link}: Pipeline #{pipeline_link} of #{ref_type} #{branch_link} by #{user_combined_name} #{humanized_status} in #{pretty_duration(duration)}"
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
