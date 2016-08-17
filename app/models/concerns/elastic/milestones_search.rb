module Elastic
  module MilestonesSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings _parent: { type: 'project' } do
        indexes :id,          type: :integer
        indexes :title,       type: :string,
                              index_options: 'offsets'
        indexes :description, type: :string,
                              index_options: 'offsets'
        indexes :project_id,  type: :integer
        indexes :created_at,  type: :date
        indexes :updated_at,  type: :date
      end

      def as_indexed_json(options = {})
        as_json(
          only: [:id, :title, :description, :project_id, :created_at, :updated_at]
        )
      end

      def self.nested?
        true
      end

      def self.elastic_search(query, options: {})
        options[:in] = %w(title^2 description)

        query_hash = basic_query_hash(options[:in], query)

        query_hash = project_ids_filter(query_hash, options[:project_ids], options[:public_and_internal_projects])

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
