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
    #     attributes = Gitlab::Git::AttributesInfoParser.new(some_repo.path)
    #
    #     attributes.attributes('README.md') # => { "eol" => "lf }
    class AttributesInfoParser < AttributesParser
      # path - The path to the Git repository.
      def initialize(path)
        @repo_path = File.expand_path(path)
        @patterns = nil
      end

      # Iterates over every line in the attributes file.
      def each_line
        full_path = File.join(@repo_path, 'info/attributes')

        return unless File.exist?(full_path)

        File.open(full_path, 'r') do |handle|
          handle.each_line do |line|
            break unless line.valid_encoding?

            yield line.strip
          end
        end
      end
    end
  end
end
