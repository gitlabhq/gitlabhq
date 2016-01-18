module MergeRequestsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,            type: :integer, index: :not_analyzed

      indexes :iid,           type: :integer, index: :not_analyzed
      indexes :target_branch, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :source_branch, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :title,         type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :description,   type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :created_at,    type: :date
      indexes :updated_at,    type: :date
      indexes :state,         type: :string
      indexes :merge_status,  type: :string

      indexes :source_project_id, type: :integer, index: :not_analyzed
      indexes :target_project_id, type: :integer, index: :not_analyzed
      indexes :author_id,         type: :integer, index: :not_analyzed

      indexes :source_project,  type: :nested
      indexes :target_project,  type: :nested
      indexes :author,          type: :nested

      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json(
        include: {
          source_project: { only: :id },
          target_project: { only: :id },
          author:         { only: :id }
        }
      ).merge({ updated_at_sort: updated_at })
    end

    def self.elastic_search(query, options: {})
      options[:in] = %w(title^2 description)

      query_hash = basic_query_hash(options[:in], query)

      if options[:projects_ids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          or: [
            {
              terms: {
                source_project_id: [options[:projects_ids]].flatten
              }
            },
            {
              terms: {
                target_project_id: [options[:projects_ids]].flatten
              }
            }
          ]
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
