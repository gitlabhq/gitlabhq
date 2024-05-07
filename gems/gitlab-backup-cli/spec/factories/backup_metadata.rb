# frozen_string_literal: true

FactoryBot.define do
  factory :backup_metadata, class: 'Gitlab::Backup::Cli::Metadata::BackupMetadata' do
    skip_create

    gitlab_version { '16.9.1-ee' }

    initialize_with { Gitlab::Backup::Cli::Metadata::BackupMetadata.build(gitlab_version: gitlab_version) }
  end
end
