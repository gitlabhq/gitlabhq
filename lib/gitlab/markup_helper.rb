# frozen_string_literal: true

module Gitlab
  module MarkupHelper
    extend self

    MARKDOWN_EXTENSIONS = %w[mdown mkd mkdn md markdown rmd].freeze
    ASCIIDOC_EXTENSIONS = %w[adoc ad asciidoc].freeze
    OTHER_EXTENSIONS = %w[textile rdoc org creole wiki mediawiki rst].freeze
    EXTENSIONS = MARKDOWN_EXTENSIONS + ASCIIDOC_EXTENSIONS + OTHER_EXTENSIONS
    PLAIN_FILENAMES = %w[readme index].freeze

    # Public: Determines if a given filename is compatible with GitHub::Markup.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def markup?(filename)
      EXTENSIONS.include?(extension(filename))
    end

    # Public: Determines if a given filename is compatible with
    # GitLab-flavored Markdown.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def gitlab_markdown?(filename)
      MARKDOWN_EXTENSIONS.include?(extension(filename))
    end

    # Public: Determines if the given filename has AsciiDoc extension.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def asciidoc?(filename)
      ASCIIDOC_EXTENSIONS.include?(extension(filename))
    end

    # Public: Determines if the given filename is plain text.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def plain?(filename)
      extension(filename) == 'txt' || plain_filename?(filename)
    end

    def previewable?(filename)
      markup?(filename)
    end

    private

    def extension(filename)
      File.extname(filename).downcase.delete('.')
    end

    def plain_filename?(filename)
      PLAIN_FILENAMES.include?(filename.downcase)
    end
  end
end
