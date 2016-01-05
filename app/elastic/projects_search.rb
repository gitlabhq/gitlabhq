module ProjectsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,                  type: :integer, index: 'not_analyzed'

      indexes :name,                type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :path,                type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :name_with_namespace, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :path_with_namespace, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :description,         type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer

      indexes :namespace_id,        type: :integer, index: 'not_analyzed'

      indexes :created_at,          type: :date
      indexes :archived,            type: :boolean
      indexes :visibility_level,    type: :integer, index: 'not_analyzed'
      indexes :last_activity_at,    type: :date
      indexes :last_pushed_at,      type: :date

      indexes :owners,              type: :nested
      indexes :masters,             type: :nested
      indexes :developers,          type: :nested
      indexes :reporters,           type: :nested
      indexes :guests,              type: :nested

      indexes :categories,          type: :nested

      indexes :name_with_namespace_sort, type: :string, index: 'not_analyzed'
      indexes :created_at_sort, type: :string, index: 'not_analyzed'
      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options={})
      as_json(
        include: {
          owners: { only: :id },
          masters: { only: :id },
          developers: { only: :id },
          reporters: { only: :id },
          guests: { only: :id },

          categories: { only: :name}
        }
      ).merge({
        name_with_namespace: name_with_namespace,
        name_with_namespace_sort: name_with_namespace.downcase,
        path_with_namespace: path_with_namespace,
        updated_at_sort: updated_at,
        created_at_sort: created_at
      })
    end

    def self.search(query, page: 1, per: 20, options: {})

      page ||= 1

      if options[:in].blank?
        options[:in] = %w(name^10 name_with_namespace^2 path_with_namespace path^9)
      else
        options[:in].push(%w(name^10 name_with_namespace^2 path_with_namespace path^9) - options[:in])
      end

      query_hash = {
        query: {
          filtered: {
            query: {
              multi_match: {
                fields: options[:in],
                query: "#{query}",
                operator: :and
              }
            },
          },
        },
        facets: {
          namespaceFacet: {
            terms: {
              field: :namespace_id,
              all_terms: true,
              size: Namespace.count
            }
          },
          categoryFacet: {
            terms: {
              field: "categories.name",
              all_terms: true,
              # FIXME. Remove to_a
              size: Project.category_counts.to_a.count
            }
          }
        },
        size: per,
        from: per * (page.to_i - 1)
      }

      if query.blank?
        query_hash[:query][:filtered][:query] = { match_all: {} }
        query_hash[:track_scores] = true
      end

      if options[:abandoned]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          range: {
            last_pushed_at: {
              lte: "now-6M/m"
            }
          }
        }
      end

      if options[:with_push]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
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
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            namespace_id: [options[:namespace_id]].flatten
          }
        }
      end

      if options[:category]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :categories,
            filter: {
              term: { "categories.name" => options[:category] }
            }
          }
        }
      end

      if options[:non_archived]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            archived: [!options[:non_archived]].flatten
          }
        }
      end

      if options[:visibility_levels]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            visibility_level: [options[:visibility_levels]].flatten
          }
        }
      end

      if !options[:owner_id].blank?
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :owners,
            filter: {
              term: { "owners.id" => options[:owner_id] }
            }
          }
        }
      end

      if options[:pids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          ids: {
            values: options[:pids]
          }
        }
      end

      options[:order] = :default if options[:order].blank?
      order = case options[:order].to_sym
              when :newest
                { created_at_sort: { order: :asc, mode: :min } }
              when :oldest
                { created_at_sort: { order: :desc, mode: :min } }
              when :recently_updated
                { updated_at_sort: { order: :asc, mode: :min } }
              when :last_updated
                { updated_at_sort: { order: :desc, mode: :min } }
              else
                { name_with_namespace_sort: { order: :asc, mode: :min } }
              end

      query_hash[:sort] = [
        order,
        :_score
      ]

      if options[:highlight]
        query_hash[:highlight] = highlight_options(options[:in])
      end

      self.__elasticsearch__.search(query_hash)
    end
  end
end
