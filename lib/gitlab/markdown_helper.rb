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
                                      .mediawiki .rst .adoc .ad .asciidoc))
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

    # Public: Determines if the given filename has AsciiDoc extension.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def asciidoc?(filename)
      filename.downcase.end_with?(*%w(.adoc .ad .asciidoc))
    end

    def previewable?(filename)
      gitlab_markdown?(filename) || markup?(filename)
    end
  end
end
