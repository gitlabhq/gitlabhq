# frozen_string_literal: true

module Gitlab
  module Danger
    class Teammate
      attr_reader :name, :username, :role, :projects

      def initialize(options = {})
        @username = options['username']
        @name = options['name'] || @username
        @role = options['role']
        @projects = options['projects']
      end

      def markdown_name
        "[#{name}](https://gitlab.com/#{username}) (`@#{username}`)"
      end

      def in_project?(name)
        projects&.has_key?(name)
      end

      # Traintainers also count as reviewers
      def reviewer?(project, category, labels)
        has_capability?(project, category, :reviewer, labels) ||
          traintainer?(project, category, labels)
      end

      def traintainer?(project, category, labels)
        has_capability?(project, category, :trainee_maintainer, labels)
      end

      def maintainer?(project, category, labels)
        has_capability?(project, category, :maintainer, labels)
      end

      private

      def has_capability?(project, category, kind, labels)
        case category
        when :test
          area = role[/Test Automation Engineer(?:.*?, (\w+))/, 1].downcase

          area && labels.any?("devops::#{area}") if kind == :reviewer
        else
          capabilities(project).include?("#{kind} #{category}")
        end
      end

      def capabilities(project)
        Array(projects.fetch(project, []))
      end
    end
  end
end
