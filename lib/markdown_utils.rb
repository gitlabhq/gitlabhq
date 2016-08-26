# Class to have all utility functions related to markdown
class MarkdownUtils

  # Convert image urls in the markdown text to absolute urls
  def self.absolute_image_urls(markdown_text)
    if markdown_text.present?
      markdown_text.gsub(/!\[(.*?)\]\((.*?)\)/, "![\\1](#{Settings.gitlab.url}\\2)")
    else
      markdown_text
    end
  end
end
