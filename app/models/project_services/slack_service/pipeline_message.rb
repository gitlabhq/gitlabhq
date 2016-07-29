class SlackService
  class PipelineMessage < BaseMessage
    attr_reader :sha, :ref_type, :ref, :status, :project_name, :project_url,
                :user_name, :duration, :pipeline_id

    def initialize(data)
      @sha = data[:sha]
      @ref_type = data[:tag] ? 'tag' : 'branch'
      @ref = data[:ref]
      @status = data[:status]
      @project_name = data[:project][:path_with_namespace]
      @project_url = data[:project][:web_url]
      @user_name = data[:commit] && data[:commit][:author_name]
      @duration = data[:object_attributes][:duration]
      @pipeline_id = data[:object_attributes][:id]
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
      "[#{Commit.truncate_sha(sha)}](#{pipeline_url})"
    end
  end
end
