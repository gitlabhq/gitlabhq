# frozen_string_literal: true

module Ci
  class BuildRunnerPresenter < SimpleDelegator
    def artifacts
      return unless options[:artifacts]

      list = []
      list << create_archive(options[:artifacts])
      list << create_reports(options[:artifacts][:reports], expire_in: options[:artifacts][:expire_in])
      list.flatten.compact
    end

    private

    def create_archive(artifacts)
      return unless artifacts[:untracked] || artifacts[:paths]

      {
        artifact_type: :archive,
        artifact_format: :zip,
        name: artifacts[:name],
        untracked: artifacts[:untracked],
        paths: artifacts[:paths],
        when: artifacts[:when],
        expire_in: artifacts[:expire_in]
      }
    end

    def create_reports(reports, expire_in:)
      return unless reports&.any?

      reports.map do |report_type, report_paths|
        {
          artifact_type: report_type.to_sym,
          artifact_format: ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.fetch(report_type.to_sym),
          name: ::Ci::JobArtifact::DEFAULT_FILE_NAMES.fetch(report_type.to_sym),
          paths: report_paths,
          when: 'always',
          expire_in: expire_in
        }
      end
    end
  end
end
