class SlackService
  class BuildMessage < BaseMessage
    attr_reader :sha
    attr_reader :ref_type
    attr_reader :ref
    attr_reader :status
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :user_name
    attr_reader :duration

    def initialize(params, commit = true)
      @sha = params[:sha]
      @ref_type = params[:tag] ? 'tag' : 'branch'
      @ref = params[:ref]
      @project_name = params[:project_name]
      @project_url = params[:project_url]
      @status = params[:commit][:status]
      @user_name = params[:commit][:author_name]
      @duration = params[:commit][:duration]
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
      "#{project_link}: Commit #{commit_link} of #{branch_link} #{ref_type} by #{user_name} #{humanized_status} in #{duration} second(s)"
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

    def commit_url
      "#{project_url}/commit/#{sha}/builds"
    end

    def commit_link
      "[#{Commit.truncate_sha(sha)}](#{commit_url})"
    end
  end
end
