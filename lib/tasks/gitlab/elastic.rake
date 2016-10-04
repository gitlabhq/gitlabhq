namespace :gitlab do
  namespace :elastic do
    desc "GitLab | Elasticsearch | Index eveything at once"
    task :index do
      Rake::Task["gitlab:elastic:create_empty_index"].invoke
      Rake::Task["gitlab:elastic:clear_index_status"].invoke
      Rake::Task["gitlab:elastic:index_repositories"].invoke
      Rake::Task["gitlab:elastic:index_wikis"].invoke
      Rake::Task["gitlab:elastic:index_database"].invoke
    end

    desc "GitLab | Elasticsearch | Index project repositories"
    task index_repositories: :environment  do
      projects = if ENV['UPDATE_INDEX']
                   Project
                 else
                   Project.includes(:index_status).
                           where("index_statuses.id IS NULL").
                           references(:index_statuses)
                 end

      projects = apply_project_filters(projects)

      indexer = Gitlab::Elastic::Indexer.new

      projects.find_each(batch_size: 300) do |project|
        repository = project.repository

        if repository.exists? && !repository.empty?
          puts "Indexing #{project.name_with_namespace} (ID=#{project.id})..."

          index_status = IndexStatus.find_or_create_by(project: project)

          begin
            head_commit = repository.commit

            if !head_commit || index_status.last_commit == head_commit.sha
              puts "Skipped".color(:yellow)
              next
            end

            indexer.run(
              project.id,
              repository.path_to_repo,
              index_status.last_commit
            )

            # During indexing the new commits can be pushed,
            # the last_commit parameter only indicates that at least this commit is in index
            index_status.update(last_commit: head_commit.sha, indexed_at: DateTime.now)
            puts "Done!".color(:green)
          rescue StandardError => e
            puts "#{e.message}, trace - #{e.backtrace}"
          end
        end
      end
    end

    desc "GitLab | Elasticsearch | Index wiki repositories"
    task index_wikis: :environment  do
      projects = apply_project_filters(Project.with_wiki_enabled)

      projects.find_each do |project|
        unless project.wiki.empty?
          puts "Indexing wiki of #{project.name_with_namespace}..."

          begin
            project.wiki.index_blobs
            puts "Done!".color(:green)
          rescue StandardError => e
            puts "#{e.message}, trace - #{e.backtrace}"
          end
        end
      end
    end

    desc "GitLab | Elasticsearch | Index all database objects"
    task index_database: :environment do
      [Project, Issue, MergeRequest, Snippet, Note, Milestone].each do |klass|
        print "Indexing #{klass} records... "

        case klass.to_s
        when 'Note'
          Note.searchable.import_with_parent
        when 'Project', 'Snippet'
          klass.import
        else
          klass.import_with_parent
        end

        puts "done".color(:green)
      end
    end

    desc "GitLab | Elasticsearch | Create empty index"
    task create_empty_index: :environment do
      Gitlab::Elastic::Helper.create_empty_index
      puts "Index created".color(:green)
    end

    desc "GitLab | Elasticsearch | Clear indexing status"
    task clear_index_status: :environment do
      IndexStatus.destroy_all
      puts "Index status has been reset".color(:green)
    end

    desc "GitLab | Elasticsearch | Delete index"
    task delete_index: :environment do
      Gitlab::Elastic::Helper.delete_index
      puts "Index deleted".color(:green)
    end

    desc "GitLab | Elasticsearch | Recreate index"
    task recreate_index: :environment do
      Gitlab::Elastic::Helper.create_empty_index
      puts "Index recreated".color(:green)
    end

    def apply_project_filters(projects)
      if ENV['ID_FROM']
        projects = projects.where("projects.id >= ?", ENV['ID_FROM'])
      end

      if ENV['ID_TO']
        projects = projects.where("projects.id <= ?", ENV['ID_TO'])
      end

      projects
    end
  end
end
