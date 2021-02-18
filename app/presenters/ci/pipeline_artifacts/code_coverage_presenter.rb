# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CodeCoveragePresenter < Gitlab::View::Presenter::Delegated
      include Gitlab::Utils::StrongMemoize

      def for_files(filenames)
        coverage_files = raw_report["files"].select { |key| filenames.include?(key) }

        { files: coverage_files }
      end

      private

      def raw_report
        strong_memoize(:raw_report) do
          self.each_blob do |blob|
            Gitlab::Json.parse(blob)
          end
        end
      end
    end
  end
end
