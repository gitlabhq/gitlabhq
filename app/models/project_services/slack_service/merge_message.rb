class SlackService
  class MergeMessage < BaseMessage
    attr_reader :username
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :merge_request_id
    attr_reader :source_branch
    attr_reader :target_branch
    attr_reader :state

    def initialize(params)
      @username = params[:user][:username]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @merge_request_id = obj_attr[:iid]
      @source_branch = obj_attr[:source_branch]
      @target_branch = obj_attr[:target_branch]
      @state = obj_attr[:state]
    end

    def pretext
      format(message)
    end

    def attachments
      []
    end

    private

    def message
      merge_request_message
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def merge_request_message
      "#{username} #{state} merge request #{merge_request_link} in #{project_link}"
    end

    def merge_request_link
      "[##{merge_request_id}](#{merge_request_url})"
    end

    def merge_request_url
      "#{project_url}/merge_requests/#{merge_request_id}"
    end
  end
end
