# frozen_string_literal: true

module Keeps
  module Helpers
    class Milestones
      RELEASES_YML_URL = "https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/releases.yml"
      Error = Class.new(StandardError)
      Milestone = Struct.new(:version, :date, keyword_init: true)

      def before_cuttoff?(milestone:, milestones_ago:)
        Gem::Version.new(milestone) < Gem::Version.new(past_milestone(milestones_ago: milestones_ago))
      end

      def past_milestone(milestones_ago:)
        milestones[current_milestone_index + milestones_ago].version
      end

      def upcoming_milestones
        milestones.select { |milestone| Date.parse(milestone.date).future? }.reverse
      end

      private

      def current_milestone
        @current_milestone ||=
          File.read(File.expand_path('../../VERSION', __dir__))
          .gsub(/^(\d+\.\d+).*$/, '\1')
          .chomp
      end

      def current_milestone_index
        milestones.index { |milestone| milestone.version == current_milestone }
      end

      def milestones
        @milestones ||= fetch_milestones.map do |milestone|
          Milestone.new(**milestone.slice('version', 'date'))
        end
      end

      def fetch_milestones
        @milestones_yaml ||= begin
          response = Gitlab::HTTP.get(RELEASES_YML_URL)

          unless (200..299).cover?(response.code)
            raise Error,
              "Failed to get group information with response code: #{response.code} and body:\n#{response.body}"
          end

          YAML.safe_load(response.body)
        end
      end
    end
  end
end
