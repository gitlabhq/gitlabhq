module WikiRepositoriesSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Git::Repository

    self.__elasticsearch__.client = Elasticsearch::Client.new(
      host: Gitlab.config.elasticsearch.host,
      port: Gitlab.config.elasticsearch.port
    )

    def repository_id
      "wiki_#{project.id}"
    end

    def self.repositories_count
      Project.where(wiki_enabled: true).count
    end

    def client_for_indexing
      self.__elasticsearch__.client
    end

    def self.import
      ProjectWiki.__elasticsearch__.create_index! force: true

      Project.where(wiki_enabled: true).find_each do |project|
        unless project.wiki.empty?
          project.wiki.index_blobs
        end
      end
    end
  end
end
