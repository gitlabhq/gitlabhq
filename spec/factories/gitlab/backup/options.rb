# frozen_string_literal: true

FactoryBot.define do
  factory :backup_options, class: 'Backup::Options' do
    skip_create

    incremental { [false, true].sample }
    force { [false, true].sample }
    skippable_tasks { attributes_for(:backup_skippable_tasks) }
    skippable_operations { attributes_for(:backup_skippable_operations) }
    max_parallelism { rand(1..8) }
    max_storage_parallelism { rand(1..8) }
    repositories_server_side_backup { [false, true].sample }
    compression_options { attributes_for(:backup_compression_options) }
    gzip_rsyncable { [false, true].sample }

    trait :backup_id do
      backup_id { '11493107454_2018_04_25_10.6.4-ce' }
    end

    trait :previous_backup do
      previous_backup { '11493107454_2018_04_25_10.6.4-ce' }
    end

    trait :repositories_storages do
      repositories_storages { %w[storage1 storage2] }
    end

    trait :repositories_paths do
      repositories_paths { %w[group-a group-b/project-c] }
    end

    trait :skip_repositories_paths do
      skip_repositories_paths { %w[group-a/project-d group-a/project-e] }
    end

    trait :remote_directory do
      remote_directory { %w[daily weekly monthly quarterly upgrade].sample }
    end

    trait :strategy_copy do
      strategy { ::Backup::Options::Strategy::COPY }
    end

    trait :all do
      backup_id
      previous_backup
      repositories_storages
      repositories_paths
      skip_repositories_paths
      remote_directory
      strategy_copy
      skip_all
      compression_options { attributes_for(:backup_compression_options, :all) }
    end

    trait :skip_all do
      skippable_tasks { attributes_for(:backup_skippable_tasks, :skip_all) }
      skippable_operations { attributes_for(:backup_skippable_operations, :skip_all) }
    end

    trait :skip_none do
      skippable_tasks { attributes_for(:backup_skippable_tasks, :skip_none) }
      skippable_operations { attributes_for(:backup_skippable_operations, :skip_none) }
    end
  end

  factory :backup_skippable_tasks, class: 'Backup::Options::SkippableTasks' do
    skip_create

    db { [false, true].sample }
    uploads { [false, true].sample }
    builds { [false, true].sample }
    artifacts { [false, true].sample }
    lfs { [false, true].sample }
    terraform_state { [false, true].sample }
    registry { [false, true].sample }
    pages { [false, true].sample }
    repositories { [false, true].sample }
    packages { [false, true].sample }
    ci_secure_files { [false, true].sample }

    trait :skip_all do
      db { true }
      uploads { true }
      builds { true }
      artifacts { true }
      lfs { true }
      terraform_state { true }
      registry { true }
      pages { true }
      repositories { true }
      packages { true }
      ci_secure_files { true }
    end

    trait :skip_none do
      db { false }
      uploads { false }
      builds { false }
      artifacts { false }
      lfs { false }
      terraform_state { false }
      registry { false }
      pages { false }
      repositories { false }
      packages { false }
      ci_secure_files { false }
    end
  end

  factory :backup_skippable_operations, class: 'Backup::Options::SkippableOperations' do
    skip_create

    archive { [false, true].sample }
    remote_storage { [false, true].sample }

    trait :skip_all do
      archive { true }
      remote_storage { true }
    end

    trait :skip_none do
      archive { false }
      remote_storage { false }
    end
  end

  factory :backup_compression_options, class: 'Backup::Options::CompressionOptions' do
    skip_create

    trait :compression_cmd do
      'pigz --compress --stdout --fast --processes=4'
    end

    trait :decompression_cmd do
      'pigz --decompress --stdout"'
    end

    trait :all do
      compression_cmd
      decompression_cmd
    end
  end
end
