module NotesSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :note,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :project_id,  type: :integer, index: :not_analyzed
      indexes :created_at,  type: :date

      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json.merge({ updated_at_sort: updated_at })
    end

    def self.elastic_search(query, options: {})
      options[:in] = ["note"]

      query_hash = {
        query: {
          filtered: {
            query: { match: { note: query } },
          },
        }
      }

      if query.blank?
        query_hash[:query][:filtered][:query] = { match_all: {} }
        query_hash[:track_scores] = true
      end

      if options[:project_ids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            project_id: [options[:project_ids]].flatten
          }
        }
      end

      query_hash[:sort] = [
        { updated_at_sort: { order: :desc, mode: :min } },
        :_score
      ]

      query_hash[:highlight] = highlight_options(options[:in])

      self.__elasticsearch__.search(query_hash)
    end
  end
end
