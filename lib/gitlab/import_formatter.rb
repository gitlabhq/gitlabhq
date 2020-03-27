# frozen_string_literal: true

module Gitlab
  class ImportFormatter
    def comment(author, date, body)
      "\n\n*By #{author} on #{date}*\n\n#{body}"
    end

    def comments_header
      "\n\n\n**Imported comments:**\n"
    end

    def author_line(author)
      author ||= "Anonymous"
      "*Created by: #{author}*\n\n"
    end

    def assignee_line(assignee)
      assignee ||= "Anonymous"
      "*Assigned to: #{assignee}*\n\n"
    end
  end
end
