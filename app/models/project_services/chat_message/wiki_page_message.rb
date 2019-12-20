# frozen_string_literal: true

module ChatMessage
  class WikiPageMessage < BaseMessage
    attr_reader :title
    attr_reader :wiki_page_url
    attr_reader :action
    attr_reader :description

    def initialize(params)
      super

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @title = obj_attr[:title]
      @wiki_page_url = obj_attr[:url]
      @description = obj_attr[:message]

      @action =
        case obj_attr[:action]
        when "create"
          "created"
        when "update"
          "edited"
        end
    end

    def attachments
      return description if markdown

      description_message
    end

    def activity
      {
        title: "#{user_combined_name} #{action} #{wiki_page_link}",
        subtitle: "in #{project_link}",
        text: title,
        image: user_avatar
      }
    end

    private

    def message
      "#{user_combined_name} #{action} #{wiki_page_link} in #{project_link}: *#{title}*"
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
