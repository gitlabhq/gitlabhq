namespace :gitlab do
  namespace :storage do
    desc 'GitLab | Storage | Migrate existing projects to Hashed Storage'
    task migrate_to_hashed: :environment do
      legacy_projects_count = Project.with_unmigrated_storage.count

      if legacy_projects_count == 0
        puts 'There are no projects requiring storage migration. Nothing to do!'

        next
      end

      print "Enqueuing migration of #{legacy_projects_count} projects in batches of #{batch_size}"

      project_id_batches do |start, finish|
        StorageMigratorWorker.perform_async(start, finish)

        print '.'
      end

      puts ' Done!'
    end

    desc 'Gitlab | Storage | Summary of existing projects using Legacy Storage'
    task legacy_projects: :environment do
      relation_summary('projects', Project.without_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | List existing projects using Legacy Storage'
    task list_legacy_projects: :environment do
      projects_list('projects using Legacy Storage', Project.without_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | Summary of existing projects using Hashed Storage'
    task hashed_projects: :environment do
      relation_summary('projects using Hashed Storage', Project.with_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | List existing projects using Hashed Storage'
    task list_hashed_projects: :environment do
      projects_list('projects using Hashed Storage', Project.with_storage_feature(:repository))
    end

    desc 'Gitlab | Storage | Summary of project attachments using Legacy Storage'
    task legacy_attachments: :environment do
      relation_summary('attachments using Legacy Storage', legacy_attachments_relation)
    end

    desc 'Gitlab | Storage | List existing project attachments using Legacy Storage'
    task list_legacy_attachments: :environment do
      attachments_list('attachments using Legacy Storage', legacy_attachments_relation)
    end

    desc 'Gitlab | Storage | Summary of project attachments using Hashed Storage'
    task hashed_attachments: :environment do
      relation_summary('attachments using Hashed Storage', hashed_attachments_relation)
    end

    desc 'Gitlab | Storage | List existing project attachments using Hashed Storage'
    task list_hashed_attachments: :environment do
      attachments_list('attachments using Hashed Storage', hashed_attachments_relation)
    end

    def batch_size
      ENV.fetch('BATCH', 200).to_i
    end

    def project_id_batches(&block)
      Project.with_unmigrated_storage.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
        ids = relation.pluck(:id)

        yield ids.min, ids.max
      end
    end

    def legacy_attachments_relation
      Upload.joins(<<~SQL).where('projects.storage_version < :version OR projects.storage_version IS NULL', version: Project::HASHED_STORAGE_FEATURES[:attachments])
        JOIN projects
          ON (uploads.model_type='Project' AND uploads.model_id=projects.id)
      SQL
    end

    def hashed_attachments_relation
      Upload.joins(<<~SQL).where('projects.storage_version >= :version', version: Project::HASHED_STORAGE_FEATURES[:attachments])
        JOIN projects
        ON (uploads.model_type='Project' AND uploads.model_id=projects.id)
      SQL
    end

    def relation_summary(relation_name, relation)
      relation_count = relation.count
      puts "* Found #{relation_count} #{relation_name}".color(:green)

      relation_count
    end

    def projects_list(relation_name, relation)
      relation_count = relation_summary(relation_name, relation)

      projects = relation.with_route
      limit = ENV.fetch('LIMIT', 500).to_i

      return unless relation_count > 0

      puts "  ! Displaying first #{limit} #{relation_name}..." if relation_count > limit

      counter = 0
      projects.find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |project|
          counter += 1

          puts "  - #{project.full_path} (id: #{project.id})".color(:red)

          return if counter >= limit # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end
    end

    def attachments_list(relation_name, relation)
      relation_count = relation_summary(relation_name, relation)

      limit = ENV.fetch('LIMIT', 500).to_i

      return unless relation_count > 0

      puts "  ! Displaying first #{limit} #{relation_name}..." if relation_count > limit

      counter = 0
      relation.find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |upload|
          counter += 1

          puts "  - #{upload.path} (id: #{upload.id})".color(:red)

          return if counter >= limit # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end
    end
  end
end
