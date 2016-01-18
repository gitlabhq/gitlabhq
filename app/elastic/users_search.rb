module UsersSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :email,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :name,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :username,    type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :bio,         type: :string
      indexes :skype,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :linkedin,    type: :string
      indexes :twitter,     type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, analyzer: :my_analyzer
      indexes :state,       type: :string
      indexes :website_url, type: :string
      indexes :created_at,  type: :date
      indexes :admin,       type: :boolean
    end

    def as_indexed_json(options = {})
      as_json.merge({
        name_sort: name.downcase,
        updated_at_sort: updated_at,
        created_at_sort: created_at
      })
    end

    def self.elastic_search(query, options: {})
      options[:in] = %w(name^3 username^2 email)

      query_hash = basic_query_hash(options[:in], query)

      query_hash[:query][:filtered][:filter] ||= { and: [] }

      if options[:uids]
        query_hash[:query][:filtered][:filter][:and] << {
          ids: {
            values: options[:uids]
          }
        }
      end

      if options[:active]
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            state: ["active"]
          }
        }
      end

      query_hash[:sort] = [:_score]

      query_hash[:highlight] = highlight_options(options[:in])
      
      self.__elasticsearch__.search(query_hash)
    end
  end
end
