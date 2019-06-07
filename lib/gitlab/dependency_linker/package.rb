# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class Package
      attr_reader :name, :git_ref, :github_ref

      def initialize(name, git_ref, github_ref)
        @name = name
        @git_ref = git_ref
        @github_ref = github_ref
      end

      def external_ref
        @git_ref || @github_ref
      end
    end
  end
end
