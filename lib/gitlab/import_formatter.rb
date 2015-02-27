module Gitlab
  class ImportFormatter
    def comment(author, date, body)
      "\n\n*By #{author} on #{date}*\n\n#{body}"
    end

    def comments_header
      "\n\n\n**Imported comments:**\n"
    end

    def author_line(author, body)
      "*Created by: #{author}*\n\n#{body}"
    end
  end
end
