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

      reports.map do |k, v|
        {
          artifact_type: k.to_sym,
          artifact_format: :gzip,
          name: ::Ci::JobArtifact::DEFAULT_FILE_NAMES[k.to_sym],
          paths: v,
          when: 'always',
          expire_in: expire_in
        }
      end
    end
  end
end
