# frozen_string_literal: true

module Gitlab
  module Danger
    class Teammate
      attr_reader :username, :name, :markdown_name, :role, :projects, :available, :has_capacity

      # The options data are produced by https://gitlab.com/gitlab-org/gitlab-roulette/-/blob/master/lib/team_member.rb
      def initialize(options = {})
        @username = options['username']
        @name = options['name']
        @markdown_name = options['markdown_name']
        @role = options['role']
        @projects = options['projects']
        @available = options['available']
        @has_capacity = options['has_capacity']
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
          area = role[/Software Engineer in Test(?:.*?, (\w+))/, 1]

          area && labels.any?("devops::#{area.downcase}") if kind == :reviewer
        when :engineering_productivity
          return false unless role[/Engineering Productivity/]
          return true if kind == :reviewer

          capabilities(project).include?("#{kind} backend")
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
