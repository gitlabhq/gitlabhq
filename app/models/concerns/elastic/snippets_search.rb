module Elastic
  module SnippetsSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings do
        indexes :id,               type: :integer

        indexes :title,            type: :string,
                                   index_options: 'offsets'
        indexes :file_name,        type: :string,
                                   index_options: 'offsets'
        indexes :content,          type: :string,
                                   index_options: 'offsets'
        indexes :created_at,       type: :date
        indexes :updated_at,       type: :date
        indexes :state,            type: :string

        indexes :project_id,       type: :integer
        indexes :author_id,        type: :integer
        indexes :visibility_level, type: :integer

        indexes :updated_at_sort,  type: :date,   index: :not_analyzed
      end

      def as_indexed_json(options = {})
        as_json({
          only: [
            :id,
            :title,
            :file_name,
            :content,
            :created_at,
            :updated_at,
            :state,
            :project_id,
            :author_id,
            :visibility_level
          ]
        })
      end

      def self.elastic_search(query, options: {})
        query_hash = basic_query_hash(%w(title file_name), query)

        query_hash = filter(query_hash, options[:user])

        self.__elasticsearch__.search(query_hash)
      end

      def self.elastic_search_code(query, options: {})
        query_hash = {
          query: {
            bool: {
              must: [{ match: { content: query } }]
            }
          }
        }

        query_hash = filter(query_hash, options[:user])

        query_hash[:sort] = [
          { updated_at_sort: { order: :desc, mode: :min } },
          :_score
        ]

        query_hash[:highlight] = { fields: { content: {} } }

        self.__elasticsearch__.search(query_hash)
      end

      def self.filter(query_hash, user)
        return query_hash if user && user.admin?

        filter = if user
                   {
                     bool: {
                       should: [
                         { terms: { visibility_level: [Snippet::PUBLIC, Snippet::INTERNAL] } },
                         { term: { author_id: user.id } },
                         { terms: { project_id: user.authorized_projects.pluck(:id) } },
                       ]
                     }
                   }
                 else
                   { term: { visibility_level: Snippet::PUBLIC } }
                 end

        query_hash[:query][:bool][:filter] = filter
        query_hash
      end
    end
  end
end
