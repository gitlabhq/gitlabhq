# frozen_string_literal: true

require 'set'

module Gitlab
  # Module that can be used to detect if a path points to a special file such as
  # a README or a CONTRIBUTING file.
  module FileDetector
    PATTERNS = {
      # Project files
      readme: /\A(#{Regexp.union(*Gitlab::MarkupHelper::PLAIN_FILENAMES).source})(\.(#{Regexp.union(*Gitlab::MarkupHelper::EXTENSIONS).source}))?\z/i,
      changelog: %r{\A(changelog|history|changes|news)[^/]*\z}i,
      license: %r{\A((un)?licen[sc]e|copying)(\.[^/]+)?\z}i,
      contributing: %r{\Acontributing[^/]*\z}i,
      version: 'version',
      avatar: /\Alogo\.(png|jpg|gif)\z/,
      issue_template: %r{\A\.gitlab/issue_templates/[^/]+\.md\z},
      merge_request_template: %r{\A\.gitlab/merge_request_templates/[^/]+\.md\z},
      metrics_dashboard: %r{\A\.gitlab/dashboards/[^/]+\.yml\z},
      xcode_config: %r{\A[^/]*\.(xcodeproj|xcworkspace)(/.+)?\z},

      # Configuration files
      gitignore: '.gitignore',
      gitlab_ci: '.gitlab-ci.yml',
      route_map: '.gitlab/route-map.yml',

      # Dependency files
      cartfile: %r{\ACartfile[^/]*\z},
      composer_json: 'composer.json',
      gemfile: /\A(Gemfile|gems\.rb)\z/,
      gemfile_lock: 'Gemfile.lock',
      gemspec: %r{\A[^/]*\.gemspec\z},
      godeps_json: 'Godeps.json',
      package_json: 'package.json',
      podfile: 'Podfile',
      podspec_json: %r{\A[^/]*\.podspec\.json\z},
      podspec: %r{\A[^/]*\.podspec\z},
      requirements_txt: %r{\A[^/]*requirements\.txt\z},
      yarn_lock: 'yarn.lock',

      # OpenAPI Specification files
      openapi: %r{.*(openapi|swagger).*\.(yaml|yml|json)\z}i
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
      PATTERNS.each do |type, search|
        did_match = if search.is_a?(Regexp)
                      path =~ search
                    else
                      path.casecmp(search) == 0
                    end

        return type if did_match
      end

      nil
    end
  end
end
