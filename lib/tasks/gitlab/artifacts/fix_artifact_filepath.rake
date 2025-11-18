# frozen_string_literal: true

desc 'GitLab | Artifacts | Fix uploaded filenames for artifacts on local storage by renaming them appropriately'
namespace :gitlab do
  namespace :artifacts do
    task fix_artifact_filepath: :environment do
      require 'resolv-replace'
      logger = Logger.new($stdout)

      helper = Gitlab::LocalAndRemoteStorageMigration::ArtifactLocalStorageNameFixer.new(logger)

      helper.rename_artifacts
    end
  end
end
