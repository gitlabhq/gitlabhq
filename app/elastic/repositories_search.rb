module RepositoriesSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Git::Repository

    self.__elasticsearch__.client = Elasticsearch::Client.new host: Gitlab.config.elasticsearch.host, port: Gitlab.config.elasticsearch.port

    def repository_id
      project.id
    end

    def self.repositories_count
      Project.count
    end

    def client_for_indexing
      self.__elasticsearch__.client
    end

    def self.import
      Repository.__elasticsearch__.create_index! force: true

      Project.find_each do |project|
        if project.repository.exists? && !project.repository.empty?
          begin
            project.repository.index_commits
          rescue
          end
          begin
            project.repository.index_blobs
          rescue
          end
        end
      end
    end
  end
end
