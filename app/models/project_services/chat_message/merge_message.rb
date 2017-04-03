module ChatMessage
  class MergeMessage < BaseMessage
    attr_reader :user_name
    attr_reader :user_avatar
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :merge_request_id
    attr_reader :source_branch
    attr_reader :target_branch
    attr_reader :state
    attr_reader :title
    attr_reader :markdown_format

    def initialize(params)
      @user_name = params[:user][:username]
      @user_avatar = params[:user][:avatar_url]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @merge_request_id = obj_attr[:iid]
      @source_branch = obj_attr[:source_branch]
      @target_branch = obj_attr[:target_branch]
      @state = obj_attr[:state]
      @title = format_title(obj_attr[:title])
      @markdown_format = params[:format]
    end

    def activity
      {
        title: "Merge Request #{state} by #{user_name}",
        subtitle: "to: #{project_link}",
        text: merge_request_link,
        image: user_avatar
      }
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
      link(project_name, project_url)
    end

    def merge_request_message
      "#{user_name} #{state} #{merge_request_link} in #{project_link}: #{title}"
    end

    def merge_request_link
      link("merge request !#{merge_request_id}", merge_request_url)
    end

    def merge_request_url
      "#{project_url}/merge_requests/#{merge_request_id}"
    end
  end
end
