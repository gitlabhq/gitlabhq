namespace :gitlab do
  namespace :elastic do
    desc "Indexing repositories"
    task index_repository: :environment  do
      Repository.import
    end

    desc "Indexing all wikis"
    task index_wiki: :environment  do
      ProjectWiki.import
    end

    desc "Create indexes in the Elasticsearch from database records"
    task create_index: :environment do
      [Project, User, Issue, MergeRequest, Snippet, Note, Milestone].each do |klass|
        klass.__elasticsearch__.create_index!
        klass.import
      end
    end
  end
end