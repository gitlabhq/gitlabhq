module Elastic
  module ApplicationSearch
    extend ActiveSupport::Concern
    extend Gitlab::CurrentSettings

    included do
      include Elasticsearch::Model

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      settings \
        index: {
          analysis: {
            analyzer: {
              default: {
                tokenizer: "standard",
                filter: ["standard", "lowercase", "my_stemmer"]
              }
            },
            filter: {
              my_stemmer: {
                type: "stemmer",
                name: "light_english"
              }
            }
          }
        }

      after_commit on: :create do
        if current_application_settings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id)
        end
      end

      after_commit on: :update do
        if current_application_settings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(
            :update,
            self.class.to_s,
            self.id,
            changed_fields: self.previous_changes.keys
          )
        end
      end

      after_commit on: :destroy do
        if current_application_settings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(
            :delete,
            self.class.to_s,
            self.id,
            project_id: self.es_parent
          )
        end
      end

      # Should be overridden in the models where some records should be skipped
      def searchable?
        true
      end

      def es_parent
        return project_id if respond_to?(:project_id)
      end
    end

    module ClassMethods
      def highlight_options(fields)
        es_fields = fields.map { |field| field.split('^').first }.inject({}) do |memo, field|
          memo[field.to_sym] = {}
          memo
        end

        { fields: es_fields }
      end

      def import_with_parent(options = {})
        transform = lambda do |r|
          { index: { _id: r.id, _parent: r.es_parent, data: r.__elasticsearch__.as_indexed_json } }
        end

        options.merge!(transform: transform)

        self.import(options)
      end

      def basic_query_hash(fields, query)
        query_hash = if query.present?
                       {
                         query: {
                           bool: {
                             must: [{
                               multi_match: {
                                 fields: fields,
                                 query: query,
                                 operator: :and
                               }
                             }]
                           }
                         }
                       }
                     else
                       {
                         query: {
                           bool: {
                             must: { match_all: {} }
                           }
                         },
                         track_scores: true
                       }
                     end

        query_hash[:sort] = [
          { updated_at: { order: :desc } },
          :_score
        ]

        query_hash[:highlight] = highlight_options(fields)

        query_hash
      end

      def iid_query_hash(query_hash, iid)
        {
          query: {
            bool: {
               must: [{ term: { iid: iid } }]
            }
          }
        }
      end

      def project_ids_filter(query_hash, project_ids, public_and_internal_projects = true)
        if project_ids
          condition = project_ids_condition(project_ids, public_and_internal_projects)

          query_hash[:query][:bool][:filter] = {
            has_parent: {
              parent_type: "project",
              query: {
                bool: {
                  should: condition
                }
              }
            }
          }
        end

        query_hash
      end

      def project_ids_condition(project_ids, public_and_internal_projects)
        conditions = [{
          terms: { id: project_ids }
        }]

        if public_and_internal_projects
          conditions << {
            term: { visibility_level: Project::PUBLIC }
          }

          conditions << {
            term: { visibility_level: Project::INTERNAL }
          }
        end

        conditions
      end
    end
  end
end
