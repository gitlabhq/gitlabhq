# frozen_string_literal: true

module Ml
  module ExperimentTracking
    class HandleCandidateGitlabMetadataService
      def initialize(candidate, metadata)
        @candidate = candidate
        @metadata = metadata.index_by { |m| m[:key] }
      end

      def execute
        handle_build_metadata(@metadata['gitlab.CI_JOB_ID'])

        @candidate.save
      end

      private

      def handle_build_metadata(build_metadata)
        return unless build_metadata

        build = Ci::Build.find_by_id(build_metadata[:value])

        raise ArgumentError, 'gitlab.CI_JOB_ID must refer to an existing build' unless build

        @candidate.ci_build = build
      end
    end
  end
end
