module ChatMessage
  class IssueMessage < BaseMessage
    attr_reader :user_name
    attr_reader :user_avatar
    attr_reader :title
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :issue_iid
    attr_reader :issue_url
    attr_reader :action
    attr_reader :state
    attr_reader :description
    attr_reader :markdown_format

    def initialize(params)
      @user_name = params[:user][:username]
      @user_avatar = params[:user][:avatar_url]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @title = obj_attr[:title]
      @issue_iid = obj_attr[:iid]
      @issue_url = obj_attr[:url]
      @action = obj_attr[:action]
      @state = obj_attr[:state]
      @description = obj_attr[:description] || ''
      @markdown_format = params[:format]
    end

    def attachments
      return [] unless opened_issue?

      markdown_format ? description : description_message
    end

    def activity
      {
        title: "Issue #{state} by #{user_name}",
        subtitle: "to: #{project_link}",
        text: issue_link,
        image: user_avatar
      }
    end

    private

    def message
      "[#{project_link}] Issue #{issue_link} #{state} by #{user_name}"
    end

    def opened_issue?
      action == "open"
    end

    def description_message
      [{
        title: issue_title,
        title_link: issue_url,
        text: format(description),
        color: "#C95823"
       }]
    end

    def project_link
      link(project_name, project_url)
    end

    def issue_link
      link(issue_title, issue_url)
    end

    def issue_title
      "##{issue_iid} #{title}"
    end
  end
end
