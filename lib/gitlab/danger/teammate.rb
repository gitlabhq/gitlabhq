# frozen_string_literal: true

module Gitlab
  module Danger
    class Teammate
      attr_reader :name, :username, :projects

      def initialize(options = {})
        @name = options['name']
        @username = options['username']
        @projects = options['projects']
      end

      def markdown_name
        "[#{name}](https://gitlab.com/#{username}) (`@#{username}`)"
      end

      def in_project?(name)
        projects&.has_key?(name)
      end

      # Traintainers also count as reviewers
      def reviewer?(project, category)
        capabilities(project).include?("reviewer #{category}") || traintainer?(project, category)
      end

      def traintainer?(project, category)
        capabilities(project).include?("trainee_maintainer #{category}")
      end

      def maintainer?(project, category)
        capabilities(project).include?("maintainer #{category}")
      end

      private

      def capabilities(project)
        Array(projects.fetch(project, []))
      end
    end
  end
end
