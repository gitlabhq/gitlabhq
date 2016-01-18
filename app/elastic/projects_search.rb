module ProjectsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,                  type: :integer, index: 'not_analyzed'

      indexes :name,                type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :path,                type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :name_with_namespace, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :path_with_namespace, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :description,         type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer

      indexes :namespace_id,        type: :integer, index: 'not_analyzed'

      indexes :created_at,          type: :date
      indexes :archived,            type: :boolean
      indexes :visibility_level,    type: :integer, index: 'not_analyzed'
      indexes :last_activity_at,    type: :date
      indexes :last_pushed_at,      type: :date
    end

    def as_indexed_json(options = {})
      as_json.merge({
        name_with_namespace: name_with_namespace,
        path_with_namespace: path_with_namespace
      })
    end

    def self.elastic_search(query, options: {})
      options[:in] = %w(name^10 name_with_namespace^2 path_with_namespace path^9)

      query_hash = basic_query_hash(options[:in], query)

      filters = []

      if options[:abandoned]
        filters << {
          range: {
            last_pushed_at: {
              lte: "now-6M/m"
            }
          }
        }
      end

      if options[:with_push]
        filters << {
          not: {
            missing: {
              field: :last_pushed_at,
              existence: true,
              null_value: true
            }
          }
        }
      end

      if options[:namespace_id]
        filters << {
          terms: {
            namespace_id: [options[:namespace_id]].flatten
          }
        }
      end

      if options[:non_archived]
        filters << {
          terms: {
            archived: [!options[:non_archived]].flatten
          }
        }
      end

      if options[:visibility_levels]
        filters << {
          terms: {
            visibility_level: [options[:visibility_levels]].flatten
          }
        }
      end

      if !options[:owner_id].blank?
        filters << {
          nested: {
            path: :owner,
            filter: {
              term: { "owner.id" => options[:owner_id] }
            }
          }
        }
      end

      if options[:pids]
        filters << {
          ids: {
            values: options[:pids]
          }
        }
      end

      query_hash[:query][:filtered][:filter] = { and: filters }

      query_hash[:sort] = [:_score]

      query_hash[:highlight] = highlight_options(options[:in])
      

      self.__elasticsearch__.search(query_hash)
    end
  end
end
