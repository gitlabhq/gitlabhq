namespace :gitlab do
  namespace :storage do
    desc 'GitLab | Storage | Migrate existing projects to Hashed Storage'
    task migrate_to_hashed: :environment do
      storage_migrator = Gitlab::HashedStorage::Migrator.new
      helper = Gitlab::HashedStorage::RakeHelper

      if helper.range_single_item?
        project = Project.with_unmigrated_storage.find_by(id: helper.range_from)

        unless project
          puts "There are no projects requiring storage migration with ID=#{helper.range_from}"

          next
        end

        puts "Enqueueing storage migration of #{project.full_path} (ID=#{project.id})..."
        storage_migrator.migrate(project)

        next
      end

      legacy_projects_count = Project.with_unmigrated_storage.count

      if legacy_projects_count == 0
        puts 'There are no projects requiring storage migration. Nothing to do!'

        next
      end

      print "Enqueuing migration of #{legacy_projects_count} projects in batches of #{helper.batch_size}"

      helper.project_id_batches do |start, finish|
        storage_migrator.bulk_schedule(start, finish)

        print '.'
      end

      puts ' Done!'
    end

    desc 'Gitlab | Storage | Summary of existing projects using Legacy Storage'
    task legacy_projects: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.relation_summary('projects using Legacy Storage', Project.without_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | List existing projects using Legacy Storage'
    task list_legacy_projects: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.projects_list('projects using Legacy Storage', Project.without_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | Summary of existing projects using Hashed Storage'
    task hashed_projects: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.relation_summary('projects using Hashed Storage', Project.with_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | List existing projects using Hashed Storage'
    task list_hashed_projects: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.projects_list('projects using Hashed Storage', Project.with_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | Summary of project attachments using Legacy Storage'
    task legacy_attachments: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.relation_summary('attachments using Legacy Storage', helper.legacy_attachments_relation)
    end

    desc 'Gitlab | Storage | List existing project attachments using Legacy Storage'
    task list_legacy_attachments: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.attachments_list('attachments using Legacy Storage', helper.legacy_attachments_relation)
    end

    desc 'Gitlab | Storage | Summary of project attachments using Hashed Storage'
    task hashed_attachments: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.relation_summary('attachments using Hashed Storage', helper.hashed_attachments_relation)
    end

    desc 'Gitlab | Storage | List existing project attachments using Hashed Storage'
    task list_hashed_attachments: :environment do
      helper = Gitlab::HashedStorage::RakeHelper
      helper.attachments_list('attachments using Hashed Storage', helper.hashed_attachments_relation)
    end
  end
end
