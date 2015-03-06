class SlackService
  class IssueMessage < BaseMessage
    attr_reader :user_name
    attr_reader :title
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :issue_iid
    attr_reader :issue_url
    attr_reader :action
    attr_reader :state
    attr_reader :description

    def initialize(params)
      @user_name = params[:user][:name]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @title = obj_attr[:title]
      @issue_iid = obj_attr[:iid]
      @issue_url = obj_attr[:url]
      @action = obj_attr[:action]
      @state = obj_attr[:state]
      @description = obj_attr[:description]
    end

    def attachments
      return [] unless opened_issue?

      description_message
    end

    private

    def message
      "#{user_name} #{state} #{issue_link} in #{project_link}: *#{title}*"
    end

    def opened_issue?
      action == "open"
    end

    def description_message
      [{ text: format(description), color: attachment_color }]
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def issue_link
      "[issue ##{issue_iid}](#{issue_url})"
    end
  end
end
