module Elastic
  module MergeRequestsSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings do
        indexes :id,            type: :integer

        indexes :iid,           type: :integer
        indexes :target_branch, type: :string,
                                index_options: 'offsets'
        indexes :source_branch, type: :string,
                                index_options: 'offsets'
        indexes :title,         type: :string,
                                index_options: 'offsets'
        indexes :description,   type: :string,
                                index_options: 'offsets'
        indexes :created_at,    type: :date
        indexes :updated_at,    type: :date
        indexes :state,         type: :string
        indexes :merge_status,  type: :string

        indexes :source_project_id, type: :integer
        indexes :target_project_id, type: :integer
        indexes :author_id,         type: :integer

        indexes :updated_at_sort, type: :string, index: 'not_analyzed'
      end

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        data = {}

        [
          :id,
          :iid,
          :target_branch,
          :source_branch,
          :title,
          :description,
          :created_at,
          :updated_at,
          :state,
          :merge_status,
          :source_project_id,
          :target_project_id,
          :author_id
        ].each do |attr|
          data[attr.to_s] = self.send(attr)
        end

        data['updated_at_sort'] = updated_at
        data
      end

      def self.elastic_search(query, options: {})
        if query =~ /#(\d+)\z/
          query_hash = iid_query_hash(query_hash, $1)
        else
          query_hash = basic_query_hash(%w(title^2 description), query)
        end

        if options[:project_ids]
          query_hash[:query][:bool][:filter] = [{
            terms: {
              target_project_id: [options[:project_ids]].flatten
            }
          }]
        end

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
