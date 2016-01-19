namespace :gitlab do
  namespace :elastic do
    desc "Indexing repositories"
    task index_repositories: :environment  do
      Repository.import
    end

    desc "Indexing all wikis"
    task index_wikis: :environment  do
      ProjectWiki.import
    end

    desc "Create indexes in the Elasticsearch from database records"
    task index_database: :environment do
      [Project, Issue, MergeRequest, Snippet, Note, Milestone].each do |klass|
        klass.__elasticsearch__.create_index!
        klass.import
      end
    end
  end
end