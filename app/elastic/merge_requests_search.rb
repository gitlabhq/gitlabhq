module MergeRequestsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,            type: :integer, index: :not_analyzed

      indexes :iid,           type: :integer, index: :not_analyzed
      indexes :target_branch, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :source_branch, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :title,         type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :description,   type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :created_at,    type: :date
      indexes :updated_at,    type: :date
      indexes :state,         type: :string
      indexes :merge_status,  type: :string

      indexes :source_project_id, type: :integer, index: :not_analyzed
      indexes :target_project_id, type: :integer, index: :not_analyzed
      indexes :author_id,         type: :integer, index: :not_analyzed
      #indexes :assignee_id,       type: :integer, index: :not_analyzed

      indexes :source_project,  type: :nested
      indexes :target_project,  type: :nested
      indexes :author,          type: :nested
      #indexes :assignee,        type: :nested

      indexes :title_sort, type: :string, index: 'not_analyzed'
      indexes :created_at_sort, type: :string, index: 'not_analyzed'
      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json(
        include: {
          source_project: { only: :id },
          target_project: { only: :id },
          author:         { only: :id },
          #assignee: { only: :id }
        }
      ).merge({
        title_sort: title.downcase,
        updated_at_sort: updated_at,
        created_at_sort: created_at
      })
    end

    def self.elastic_search(query, page: 1, per: 20, options: {})

      page ||= 1

      if options[:in].blank?
        options[:in] = %w(title^2 description)
      else
        options[:in].push(%w(title^2 description) - options[:in])
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
          targetProjectFacet: {
            terms: {
              field: :target_project_id,
              all_terms: true,
              size: Project.count
            }
          }
        },
        size: per,
        from: per * (page.to_i - 1)
      }

      if query.blank?
        query_hash[:query][:filtered][:query] = { match_all: {}}
        query_hash[:track_scores] = true
      end

      if options[:projects_ids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          or: [
            terms: {
              source_project_id: [options[:projects_ids]].flatten
            },
            terms: {
              target_project_id: [options[:projects_ids]].flatten
            }
          ]
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
                { title_sort: { order: :asc, mode: :min } }
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
