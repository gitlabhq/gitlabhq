module SnippetsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer

      indexes :title,       type: :string,
                            index_options: 'offsets'
      indexes :file_name,   type: :string,
                            index_options: 'offsets'
      indexes :content,     type: :string,
                            index_options: 'offsets'
      indexes :created_at,  type: :date
      indexes :updated_at,  type: :date
      indexes :state,       type: :string

      indexes :project_id,  type: :integer
      indexes :author_id,   type: :integer

      indexes :project,     type: :nested
      indexes :author,      type: :nested

      indexes :updated_at_sort, type: :date,   index: :not_analyzed
    end

    def as_indexed_json(options = {})
      as_json(
        include: {
          project:  { only: :id },
          author:   { only: :id }
        }
      )
    end

    def self.elastic_search(query, options: {})
      query_hash = basic_query_hash(%w(title file_name), query)

      query_hash = limit_ids(query_hash, options[:ids])

      self.__elasticsearch__.search(query_hash)
    end

    def self.elastic_search_code(query, options: {})
      query_hash = {
        query: {
          filtered: {
            query: { match: { content: query } },
          },
        }
      }

      query_hash = limit_ids(query_hash, options[:ids])

      query_hash[:sort] = [
        { updated_at_sort: { order: :desc, mode: :min } },
        :_score
      ]

      query_hash[:highlight] = { fields: { content: {} } }

      self.__elasticsearch__.search(query_hash)
    end

    def self.limit_ids(query_hash, ids)
      if ids
        query_hash[:query][:filtered][:filter] = {
          and: [ { terms: { id: ids } } ]
        }
      end

      query_hash
    end
  end
end
