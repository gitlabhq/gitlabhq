module Elastic
  module IssuesSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings do
        indexes :id,          type: :integer

        indexes :iid,         type: :integer, index: :not_analyzed
        indexes :title,       type: :string,
                              index_options: 'offsets'
        indexes :description, type: :string,
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
        data = {}

        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        [:id, :iid, :title, :description, :created_at, :updated_at, :state, :project_id, :author_id].each do |attr|
          data[attr.to_s] = self.send(attr)
        end

        data['project'] = { 'id' => project.id }
        data['author'] = { 'id' => author.id }
        data['updated_at_sort'] = updated_at
        data
      end

      def self.elastic_search(query, options: {})
        if query =~ /#(\d+)\z/
          query_hash = iid_query_hash(query_hash, $1)
        else
          query_hash = basic_query_hash(%w(title^2 description), query)
        end

        query_hash = project_ids_filter(query_hash, options[:project_ids])

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
