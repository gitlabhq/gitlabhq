class SlackService
  class MergeMessage < BaseMessage
    attr_reader :user_name
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :merge_request_id
    attr_reader :source_branch
    attr_reader :target_branch
    attr_reader :state
    attr_reader :title

    def initialize(params)
      @user_name = params[:user][:name]
      @project_name = params[:project_name]
      @project_url = params[:project_url]
      @action = params[:object_attributes][:action]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @merge_request_id = obj_attr[:iid]
      @source_branch = obj_attr[:source_branch]
      @target_branch = obj_attr[:target_branch]
      @state = obj_attr[:state]
      @title = format_title(obj_attr[:title])
    end

    def pretext
      format(message)
    end

    def attachments
      []
    end

    private

    def format_title(title)
      '*' + title.lines.first.chomp + '*'
    end

    def message
      merge_request_message
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def merge_request_message
      "#{user_name} #{state_or_action_text} #{merge_request_link} in #{project_link}: #{title}"
    end

    def merge_request_link
      "[merge request !#{merge_request_id}](#{merge_request_url})"
    end

    def merge_request_url
      "#{project_url}/merge_requests/#{merge_request_id}"
    end

    def state_or_action_text
      @action == 'approved' ? @action : state
    end
  end
end
