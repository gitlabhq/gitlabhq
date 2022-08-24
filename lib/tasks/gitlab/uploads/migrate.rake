# frozen_string_literal: true

namespace :gitlab do
  namespace :uploads do
    desc "GitLab | Uploads | Migrate all uploaded files to object storage"
    task 'migrate:all' => :migrate

    # The following is the actual rake task that migrates uploads of specified
    # category to object storage
    desc 'GitLab | Uploads | Migrate the uploaded files of specified type to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |_t, args|
      Gitlab::Uploads::MigrationHelper.new(args, Logger.new($stdout)).migrate_to_remote_storage
    end

    desc "GitLab | Uploads | Migrate all uploaded files to local storage"
    task 'migrate_to_local:all' => :migrate_to_local

    desc 'GitLab | Uploads | Migrate the uploaded files of specified type to local storage'
    task :migrate_to_local, [:uploader_class, :model_class, :mounted_as] => :environment do |_t, args|
      Gitlab::Uploads::MigrationHelper.new(args, Logger.new($stdout)).migrate_to_local_storage
    end
  end
end
