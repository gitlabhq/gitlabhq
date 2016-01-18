module SnippetsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer, index: :not_analyzed

      indexes :title,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :file_name,   type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :content,     type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :created_at,  type: :date
      indexes :updated_at,  type: :date
      indexes :state,       type: :string

      indexes :project_id,  type: :integer, index: :not_analyzed
      indexes :author_id,   type: :integer, index: :not_analyzed

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
      options[:in] = %w(title file_name)
      
      query_hash = basic_query_hash(options[:in], query)

      if options[:ids]
        query_hash[:query][:filtered][:filter] = {
          and: [ { terms: { id: [options[:ids]].flatten } } ]
        }
      end

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

      if options[:ids]
        query_hash[:query][:filtered][:filter] = {
          and: [ { terms: { id: [options[:ids]].flatten } } ]
        }
      end

      query_hash[:sort] = [
        { updated_at_sort: { order: :desc, mode: :min } },
        :_score
      ]

      query_hash[:highlight] = { fields: {content: {}} }

      self.__elasticsearch__.search(query_hash)
    end
  end
end
