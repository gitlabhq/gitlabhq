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

    desc "GitLab | Elasticsearch | Index project repositories in the background"
    task index_repositories_async: :environment do
      print "Enqueuing project repositories in batches of #{batch_size}"

      project_id_batches do |start, finish|
        ElasticBatchProjectIndexerWorker.perform_async(start, finish, ENV['UPDATE_INDEX'])
        print "."
      end

      puts "OK"
    end

    desc "GitLab | ElasticSearch | Check project repository indexing status"
    task index_repositories_status: :environment do
      indexed = IndexStatus.count
      projects = Project.count
      percent = (indexed / projects.to_f) * 100.0

      puts "Indexing is %.2f%% complete (%d/%d projects)" % [percent, indexed, projects]
    end

    desc "GitLab | Elasticsearch | Index project repositories"
    task index_repositories: :environment  do
      print "Indexing project repositories..."

      Sidekiq::Logging.logger = Logger.new(STDOUT)
      project_id_batches do |start, finish|
        ElasticBatchProjectIndexerWorker.new.perform(start, finish, ENV['UPDATE_INDEX'])
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
      IndexStatus.delete_all
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

    def batch_size
      ENV.fetch('BATCH', 300).to_i
    end

    def project_id_batches(&blk)
      relation = Project

      unless ENV['UPDATE_INDEX']
        relation = relation.includes(:index_status).where('index_statuses.id IS NULL').references(:index_statuses)
      end

      relation.all.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation|
        ids = relation.reorder(:id).pluck(:id)
        yield ids[0], ids[-1]
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
