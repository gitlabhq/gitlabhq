namespace :gitlab do
  namespace :elastic do
    desc "GitLab | Update Elasticsearch indexes"
    task :index do
      Rake::Task["gitlab:elastic:index_repositories"].invoke
      Rake::Task["gitlab:elastic:index_wikis"].invoke
      Rake::Task["gitlab:elastic:index_database"].invoke
    end

    desc "GitLab | Update Elasticsearch indexes for project repositories"
    task index_repositories: :environment  do
      Repository.__elasticsearch__.create_index!

      projects = if ENV['UPDATE_INDEX']
                   Project
                 else
                   Project.includes(:index_status).
                           where("index_statuses.id IS NULL").
                           references(:index_statuses)
                 end

      projects = apply_project_filters(projects)

      indexer = Elastic::Indexer.new

      projects.find_each do |project|
        if project.repository.exists? && !project.repository.empty?
          puts "Indexing #{project.name_with_namespace} (ID=#{project.id})..."

          index_status = IndexStatus.find_or_create_by(project: project)

          begin
            head_sha = project.repository.commit.sha

            if index_status.last_commit == head_sha
              puts "Skipped".yellow
              next
            end

            indexer.run(
              project.id,
              project.repository.path_to_repo,
              project.index_status.last_commit
            )

            # During indexing the new commits can be pushed,
            # the last_commit parameter only indicates that at least this commit is in index
            index_status.update(last_commit: head_sha, indexed_at: DateTime.now)
            puts "Done!".green
          rescue StandardError => e
            puts "#{e.message}, trace - #{e.backtrace}"
          end
        end
      end
    end

    desc "GitLab | Update Elasticsearch indexes for wiki repositories"
    task index_wikis: :environment  do
      ProjectWiki.__elasticsearch__.create_index!

      projects = apply_project_filters(Project.where(wiki_enabled: true))

      projects.find_each do |project|
        unless project.wiki.empty?
          puts "Indexing wiki of #{project.name_with_namespace}..."
          begin
            project.wiki.index_blobs
            puts "Done!".green
          rescue StandardError => e
            puts "#{e.message}, trace - #{e.backtrace}"
          end
        end
      end
    end

    desc "GitLab | Update Elasticsearch indexes for all database objects"
    task index_database: :environment do
      [Project, Issue, MergeRequest, Snippet, Note, Milestone].each do |klass|
        klass.__elasticsearch__.create_index!

        if klass == Note
          Note.searchable.import
        else
          klass.import
        end
      end
    end

    desc "GitLab | Recreate Elasticsearch indexes for particular model"
    task reindex_model: :environment do
      model_name = ENV['MODEL']

      unless %w(Project Issue MergeRequest Snippet Note Milestone).include?(model_name)
        raise "Please pass MODEL variable"
      end

      klass = model_name.constantize
      klass.__elasticsearch__.create_index! force: true

      if klass == Note
        Note.searchable.import
      else
        klass.import
      end
    end

    desc "GitLab | Create empty Elasticsearch indexes"
    task create_empty_indexes: :environment do
      [
        Project,
        Issue,
        MergeRequest,
        Snippet,
        Note,
        Milestone,
        ProjectWiki,
        Repository
      ].each do |klass|
        klass.__elasticsearch__.create_index!
      end
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
