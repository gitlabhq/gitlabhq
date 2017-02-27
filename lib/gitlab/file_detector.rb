require 'set'

module Gitlab
  # Module that can be used to detect if a path points to a special file such as
  # a README or a CONTRIBUTING file.
  module FileDetector
    PATTERNS = {
      readme: /\Areadme/i,
      changelog: /\A(changelog|history|changes|news)/i,
      license: /\A(licen[sc]e|copying)(\..+|\z)/i,
      contributing: /\Acontributing/i,
      version: 'version',
      gitignore: '.gitignore',
      koding: '.koding.yml',
      gitlab_ci: '.gitlab-ci.yml',
      avatar: /\Alogo\.(png|jpg|gif)\z/
    }.freeze

    # Returns an Array of file types based on the given paths.
    #
    # This method can be used to check if a list of file paths (e.g. of changed
    # files) involve any special files such as a README or a LICENSE file.
    #
    # Example:
    #
    #     types_in_paths(%w{README.md foo/bar.txt}) # => [:readme]
    def self.types_in_paths(paths)
      types = Set.new

      paths.each do |path|
        type = type_of(path)

        types << type if type
      end

      types.to_a
    end

    # Returns the type of a file path, or nil if none could be detected.
    #
    # Returned types are Symbols such as `:readme`, `:version`, etc.
    #
    # Example:
    #
    #     type_of('README.md') # => :readme
    #     type_of('VERSION') # => :version
    def self.type_of(path)
      name = File.basename(path)

      PATTERNS.each do |type, search|
        did_match = if search.is_a?(Regexp)
                      name =~ search
                    else
                      name.casecmp(search) == 0
                    end

        return type if did_match
      end

      nil
    end
  end
end
