module MilestonesSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :title,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :description, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :project_id,  type: :integer, index: :not_analyzed
      indexes :created_at,  type: :date

      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json.merge({ updated_at_sort: updated_at })
    end

    def self.elastic_search(query, options: {})
      options[:in] = %w(title^2 description)

      query_hash = basic_query_hash(options[:in], query)

      query_hash = project_ids_filter(query_hash, options[:projects_ids])

      self.__elasticsearch__.search(query_hash)
    end
  end
end
