module ChatMessage
  class WikiPageMessage < BaseMessage
    attr_reader :user_name
    attr_reader :title
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :wiki_page_url
    attr_reader :action
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
      @wiki_page_url = obj_attr[:url]
      @description = obj_attr[:content]

      @action =
        case obj_attr[:action]
        when "create"
          "created"
        when "update"
          "edited"
        end

       @markdown_format = params[:format]
    end

    def activity
      {
        title: "#{user_name} #{action} #{wiki_page_link}",
        subtitle: "in: #{project_link}",
        text: title,
        image: user_avatar
      }
    end

    def attachments
      markdown_format ? @description : description_message
    end

    private

    def message
      "#{user_name} #{action} #{wiki_page_link} in #{project_link}: *#{title}*"
    end

    def description_message
      [{ text: format(@description), color: attachment_color }]
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def wiki_page_link
      "[wiki page](#{wiki_page_url})"
    end
  end
end
