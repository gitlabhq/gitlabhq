module Gitlab
  module MarkdownHelper
    module_function

    # Public: Determines if a given filename is compatible with GitHub::Markup.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def markup?(filename)
      filename.downcase.end_with?(*%w(.textile .rdoc .org .creole .wiki
                                      .mediawiki .rst .adoc .asciidoc .asc))
    end

    # Public: Determines if a given filename is compatible with
    # GitLab-flavored Markdown.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def gitlab_markdown?(filename)
      filename.downcase.end_with?(*%w(.mdown .md .markdown))
    end
  end
end
