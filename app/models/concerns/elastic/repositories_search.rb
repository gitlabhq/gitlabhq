module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      def repository_id
        project.id
      end

      def project_id
        project.id
      end

      def client_for_indexing
        self.__elasticsearch__.client
      end

      def self.import
        Project.find_each do |project|
          if project.repository.exists? && !project.repository.empty?
            project.repository.index_commits
            project.repository.index_blobs
          end
        end
      end

      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20)
        response = project.repository.search(query, type: :commit, page: page, per: per_page)[:commits][:results]

        commits = response.map do |result|
          commit result["_source"]["commit"]["sha"]
        end

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end
    end

    class_methods do
      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20, options: {})
        response = Repository.search(
          query,
          type: :commit,
          page: page,
          per: per_page,
          options: options
        )[:commits][:results]

        commits = response.map do |result|
          sha = result["_source"]["commit"]["sha"]
          project = Project.find(result["_source"]["commit"]["rid"])
          project.commit(sha)
        end

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end
    end
  end
end
