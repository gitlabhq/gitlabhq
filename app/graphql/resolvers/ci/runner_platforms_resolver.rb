# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerPlatformsResolver < BaseResolver
      type Types::Ci::RunnerPlatformType.connection_type, null: true
      description 'Supported runner platforms.'

      def resolve(**args)
        runner_instructions.map do |platform, data|
          {
            name: platform, human_readable_name: data[:human_readable_name],
            architectures: parse_architectures(data[:download_locations])
          }
        end
      end

      private

      def runner_instructions
        Gitlab::Ci::RunnerInstructions::OS.merge(Gitlab::Ci::RunnerInstructions::OTHER_ENVIRONMENTS)
      end

      def parse_architectures(download_locations)
        download_locations&.map do |architecture, download_location|
          { name: architecture, download_location: download_location }
        end
      end
    end
  end
end
