namespace :gitlab do
  namespace :storage do
    desc 'GitLab | Storage | Migrate existing projects to Hashed Storage'
    task migrate_to_hashed: :environment do
      legacy_projects_count = Project.with_legacy_storage.count

      if legacy_projects_count == 0
        puts 'There are no projects using legacy storage. Nothing to do!'

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
      projects_summary(Project.with_legacy_storage)
    end

    desc 'Gitlab | Storage | List existing projects using Legacy Storage'
    task list_legacy_projects: :environment do
      projects_list(Project.with_legacy_storage)
    end

    desc 'Gitlab | Storage | Summary of existing projects using Hashed Storage'
    task hashed_projects: :environment do
      projects_summary(Project.with_hashed_storage)
    end

    desc 'Gitlab | Storage | List existing projects using Hashed Storage'
    task list_hashed_projects: :environment do
      projects_list(Project.with_hashed_storage)
    end

    def batch_size
      ENV.fetch('BATCH', 200).to_i
    end

    def project_id_batches(&block)
      Project.with_legacy_storage.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
        ids = relation.pluck(:id)

        yield ids.min, ids.max
      end
    end

    def projects_summary(relation)
      projects_count = relation.count
      puts "* Found #{projects_count} projects".color(:green)

      projects_count
    end

    def projects_list(relation)
      projects_count = projects_summary(relation)

      projects = relation.with_route
      limit = ENV.fetch('LIMIT', 500).to_i

      return unless projects_count > 0

      puts "  ! Displaying first #{limit} projects..." if projects_count > limit

      counter = 0
      projects.find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |project|
          counter += 1

          puts "  - #{project.full_path} (id: #{project.id})".color(:red)

          return if counter >= limit # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end
    end
  end
end
