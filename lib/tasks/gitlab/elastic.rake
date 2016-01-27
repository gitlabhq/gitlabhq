namespace :gitlab do
  namespace :elastic do
    desc "Indexing repositories"
    task index_repositories: :environment  do
      Repository.__elasticsearch__.create_index!

      Project.find_each do |project|
        if project.repository.exists? && !project.repository.empty?
          puts "Indexing #{project.name_with_namespace}..."

          begin
            project.repository.index_commits
            project.repository.index_blobs
            puts "Done!".green
          rescue StandardError => e
            puts "#{e.message}, trace - #{e.backtrace}"
          end
        end
      end
    end

    desc "Indexing all wikis"
    task index_wikis: :environment  do
      ProjectWiki.import
    end

    desc "Create indexes in the Elasticsearch from database records"
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
  end
end