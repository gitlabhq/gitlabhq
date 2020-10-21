# frozen_string_literal: true

module Gitlab
  module Danger
    class Teammate
      attr_reader :options, :username, :name, :role, :projects, :available, :hungry, :tz_offset_hours

      # The options data are produced by https://gitlab.com/gitlab-org/gitlab-roulette/-/blob/master/lib/team_member.rb
      def initialize(options = {})
        @options = options
        @username = options['username']
        @name = options['name']
        @markdown_name = options['markdown_name']
        @role = options['role']
        @projects = options['projects']
        @available = options['available']
        @hungry = options['hungry']
        @tz_offset_hours = options['tz_offset_hours']
      end

      def to_h
        options
      end

      def ==(other)
        return false unless other.respond_to?(:username)

        other.username == username
      end

      def in_project?(name)
        projects&.has_key?(name)
      end

      def reviewer?(project, category, labels)
        has_capability?(project, category, :reviewer, labels)
      end

      def traintainer?(project, category, labels)
        has_capability?(project, category, :trainee_maintainer, labels)
      end

      def maintainer?(project, category, labels)
        has_capability?(project, category, :maintainer, labels)
      end

      def markdown_name(author: nil)
        "#{@markdown_name} (#{utc_offset_text(author)})"
      end

      def local_hour
        (Time.now.utc + tz_offset_hours * 3600).hour
      end

      protected

      def floored_offset_hours
        floored_offset = tz_offset_hours.floor(0)

        floored_offset == tz_offset_hours ? floored_offset : tz_offset_hours
      end

      private

      def utc_offset_text(author = nil)
        offset_text =
          if floored_offset_hours >= 0
            "UTC+#{floored_offset_hours}"
          else
            "UTC#{floored_offset_hours}"
          end

        return offset_text unless author

        "#{offset_text}, #{offset_diff_compared_to_author(author)}"
      end

      def offset_diff_compared_to_author(author)
        diff = floored_offset_hours - author.floored_offset_hours
        return "same timezone as `@#{author.username}`" if diff == 0

        ahead_or_behind = diff < 0 ? 'behind' : 'ahead of'
        pluralized_hours = pluralize(diff.abs, 'hour', 'hours')

        "#{pluralized_hours} #{ahead_or_behind} `@#{author.username}`"
      end

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

      def pluralize(count, singular, plural)
        word = count == 1 || count.to_s =~ /^1(\.0+)?$/ ? singular : plural

        "#{count || 0} #{word}"
      end
    end
  end
end
