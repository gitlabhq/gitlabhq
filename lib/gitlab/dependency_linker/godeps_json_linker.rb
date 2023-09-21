# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class GodepsJsonLinker < JsonLinker
      NESTED_REPO_REGEX = %r{([^/]+/)+[^/]+?}

      self.file_type = :godeps_json

      private

      def link_dependencies
        link_json('ImportPath') do |path|
          case path
          when %r{\A(?<repo>github\.com/#{REPO_REGEX})/(?<path>.+)\z}o
            "https://#{$~[:repo]}/tree/master/#{$~[:path]}"
          when %r{\A(?<repo>gitlab\.com/#{NESTED_REPO_REGEX})\.git/(?<path>.+)\z}o,
            %r{\A(?<repo>gitlab\.com/#{REPO_REGEX})/(?<path>.+)\z}o

            "https://#{$~[:repo]}/-/tree/master/#{$~[:path]}"
          when /\Agolang\.org/
            "https://godoc.org/#{path}"
          else
            "https://#{path}"
          end
        end
      end
    end
  end
end
