module Elastic
  module ProjectsSearch
    extend ActiveSupport::Concern

    TRACKED_FEATURE_SETTINGS = %w(
      issues_access_level
      merge_requests_access_level
      snippets_access_level
      wiki_access_level
      repository_access_level
    ).freeze

    included do
      include ApplicationSearch

      mappings do
        indexes :id,                  type: :integer
        indexes :name,                type: :text,
                                      index_options: 'offsets'
        indexes :path,                type: :text,
                                      index_options: 'offsets'
        indexes :name_with_namespace, type: :text,
                                      index_options: 'offsets',
                                      analyzer: :my_ngram_analyzer
        indexes :path_with_namespace, type: :text,
                                      index_options: 'offsets'
        indexes :description,         type: :text,
                                      index_options: 'offsets'
        indexes :namespace_id,        type: :integer
        indexes :created_at,          type: :date
        indexes :updated_at,          type: :date
        indexes :archived,            type: :boolean

        indexes :visibility_level,            type: :integer
        indexes :issues_access_level,         type: :integer
        indexes :merge_requests_access_level, type: :integer
        indexes :snippets_access_level,       type: :integer
        indexes :wiki_access_level,           type: :integer
        indexes :repository_access_level,     type: :integer

        indexes :last_activity_at,    type: :date
        indexes :last_pushed_at,      type: :date
      end

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        data = {}

        [
          :id,
          :name,
          :path,
          :description,
          :namespace_id,
          :created_at,
          :updated_at,
          :archived,
          :visibility_level,
          :last_activity_at,
          :name_with_namespace,
          :path_with_namespace
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        TRACKED_FEATURE_SETTINGS.each do |feature|
          data[feature] = project_feature.public_send(feature)
        end

        data
      end

      def self.elastic_search(query, options: {})
        options[:in] = %w(name^10 name_with_namespace^2 path_with_namespace path^9 description)

        query_hash = basic_query_hash(options[:in], query)

        filters = []

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

        if options[:project_ids]
          filters << {
            bool: project_ids_query(options[:current_user], options[:project_ids], options[:public_and_internal_projects])
          }
        end

        query_hash[:query][:bool][:filter] = filters

        query_hash[:sort] = [:_score]

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
