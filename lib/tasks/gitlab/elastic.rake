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

      indexer = Gitlab::Elastic::Indexer.new

      projects.find_each do |project|
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

    desc "GitLab | Update Elasticsearch indexes for wiki repositories"
    task index_wikis: :environment  do
      ProjectWiki.__elasticsearch__.create_index!

      projects = apply_project_filters(Project.where(wiki_enabled: true))

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

    desc "GitLab | Update Elasticsearch indexes for all database objects"
    task index_database: :environment do
      [Project, Issue, MergeRequest, Snippet, Note, Milestone].each do |klass|
        klass.__elasticsearch__.create_index!

        print "Indexing #{klass} records... "

        if klass == Note
          Note.searchable.import
        else
          klass.import
        end

        puts "done".color(:green)
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

      print "Reindexing #{klass} records... "

      if klass == Note
        Note.searchable.import
      else
        klass.import
      end

      puts "done".color(:green)
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
        print "Creating index for #{klass}... "

        klass.__elasticsearch__.create_index!

        puts "done".color(:green)
      end
    end

    desc "GitLab | Clear Elasticsearch indexing status"
    task clear_index_status: :environment do
      IndexStatus.destroy_all
      puts "Done".color(:green)
    end

    desc "GitLab | Delete Elasticsearch indexes"
    task delete_indexes: :environment do
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
        print "Delete index for #{klass}... "

        klass.__elasticsearch__.delete_index!

        puts "done".color(:green)
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
