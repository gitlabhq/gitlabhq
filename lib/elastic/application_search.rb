module Elastic
  module ApplicationSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model

      self.__elasticsearch__.client = Elasticsearch::Client.new(
        host: Gitlab.config.elasticsearch.host,
        port: Gitlab.config.elasticsearch.port
      )

      index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env].join('-')

      settings \
        index: {
          analysis: {
            analyzer: {
              default:{
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
        if Gitlab.config.elasticsearch.enabled && self.searchable?
          ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id)
        end
      end

      after_commit on: :update do
        if Gitlab.config.elasticsearch.enabled && self.searchable?
          ElasticIndexerWorker.perform_async(:update, self.class.to_s, self.id)
        end
      end

      after_commit on: :destroy do
        if Gitlab.config.elasticsearch.enabled && self.searchable?
          ElasticIndexerWorker.perform_async(:delete, self.class.to_s, self.id)
        end
      end

      # Should be overridden in the models where not eveything should be indexed
      def searchable?
        true
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

      def basic_query_hash(fields, query)
        query_hash = if query.present?
                       {
                         query: {
                           filtered: {
                             query: {
                               multi_match: {
                                 fields: fields,
                                 query: query,
                                 operator: :and
                               }
                             },
                           },
                         }
                       }
                     else
                       {
                         query: {
                           filtered: {
                             query: { match_all: {} }
                           }
                         },
                         track_scores: true
                       }
                     end

        query_hash[:sort] = [
          { updated_at_sort: { order: :desc, mode: :min } },
          :_score
        ]

        query_hash[:highlight] = highlight_options(fields)

        query_hash
      end

      def iid_query_hash(query_hash, iid)
        {
          query: {
            filtered: {
               query: { match: { iid: iid } }
            }
          }
        }
      end

      def project_ids_filter(query_hash, project_ids)
        if project_ids
          query_hash[:query][:filtered][:filter] = {
            bool: {
              must: [ { terms: { project_id: project_ids } } ]
            }
          }
        end

        query_hash
      end
    end
  end
end
