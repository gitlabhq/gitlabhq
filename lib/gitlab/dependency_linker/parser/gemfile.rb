# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    module Parser
      class Gemfile < MethodLinker
        GIT_REGEX = Gitlab::DependencyLinker::GemfileLinker::GIT_REGEX
        GITHUB_REGEX = Gitlab::DependencyLinker::GemfileLinker::GITHUB_REGEX

        def initialize(plain_text)
          @plain_text = plain_text
        end

        # Returns a list of Gitlab::DependencyLinker::Package
        #
        # keyword - The package definition keyword, e.g. `:gem` for
        # Gemfile parsing, `:pod` for Podfile.
        def parse(keyword:)
          plain_lines.each_with_object([]) do |line, packages|
            name = fetch(line, method_call_regex(keyword))

            next unless name

            git_ref = fetch(line, GIT_REGEX)
            github_ref = fetch(line, GITHUB_REGEX)

            packages << Gitlab::DependencyLinker::Package.new(name, git_ref, github_ref)
          end
        end

        private

        def fetch(line, regex, group: :name)
          match = line.match(regex)
          match[group] if match
        end
      end
    end
  end
end
