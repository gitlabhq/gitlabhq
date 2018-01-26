# Gitaly note: JV: not sure what to make of this class. Why does it use
# the full disk path of the repository to look up attributes This is
# problematic in Gitaly, because Gitaly hides the full disk path to the
# repository from gitlab-ce.

module Gitlab
  module Git
    # Parses gitattributes at `$GIT_DIR/info/attributes`
    #
    # Unlike Rugged this parser only needs a single IO call (a call to `open`),
    # vastly reducing the time spent in extracting attributes.
    #
    # This class _only_ supports parsing the attributes file located at
    # `$GIT_DIR/info/attributes` as GitLab doesn't use any other files
    # (`.gitattributes` is copied to this particular path).
    #
    # Basic usage:
    #
    #     attributes = Gitlab::Git::InfoAttributes.new(some_repo.path)
    #
    #     attributes.attributes('README.md') # => { "eol" => "lf }
    class InfoAttributes
      delegate :attributes, :patterns, to: :parser

      # path - The path to the Git repository.
      def initialize(path)
        @repo_path = File.expand_path(path)
      end

      def parser
        @parser ||= begin
          if File.exist?(attributes_path)
            File.open(attributes_path, 'r') do |file_handle|
              AttributesParser.new(file_handle)
            end
          else
            AttributesParser.new("")
          end
        end
      end

      private

      def attributes_path
        @attributes_path ||= File.join(@repo_path, 'info/attributes')
      end
    end
  end
end
