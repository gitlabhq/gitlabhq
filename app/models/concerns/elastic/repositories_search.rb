module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

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
        Repository.__elasticsearch__.create_index!

        Project.find_each do |project|
          if project.repository.exists? && !project.repository.empty?
            project.repository.index_commits
            project.repository.index_blobs
          end
        end
      end
    end
  end
end
