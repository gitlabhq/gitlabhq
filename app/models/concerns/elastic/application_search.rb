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
                tokenizer: 'standard',
                filter: %w(standard lowercase my_stemmer)
              },
              my_ngram_analyzer: {
                tokenizer: 'my_ngram_tokenizer',
                filter: ['lowercase']
              }
            },
            filter: {
              my_stemmer: {
                type: 'stemmer',
                name: 'light_english'
              }
            },
            tokenizer: {
              my_ngram_tokenizer: {
                type: 'nGram',
                min_gram: 2,
                max_gram: 3,
                token_chars: %w(letter digit)
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
        project_id if respond_to?(:project_id)
      end

      # Some attributes are actually complicated methods. Bad data can cause
      # them to raise exceptions. When this happens, we still want the remainder
      # of the object to be saved, so silently swallow the errors
      def safely_read_attribute_for_elasticsearch(attr_name)
        send(attr_name)
      rescue => err
        logger.warn("Elasticsearch failed to read #{attr_name} for #{self.class} #{self.id}: #{err}")
        nil
      end
    end

    module ClassMethods
      # Should be overridden for all nested models
      def nested?
        false
      end

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

        options[:transform] = transform

        self.import(options)
      end

      def basic_query_hash(fields, query)
        query_hash = if query.present?
                       {
                         query: {
                           bool: {
                             must: [{
                               simple_query_string: {
                                 fields: fields,
                                 query: query,
                                 default_operator: :and
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

      def iid_query_hash(iid)
        {
          query: {
            bool: {
               filter: [{ term: { iid: iid } }]
            }
          }
        }
      end

      def project_ids_filter(query_hash, options)
        project_query = project_ids_query(
          options[:current_user],
          options[:project_ids],
          options[:public_and_internal_projects],
          options[:feature]
        )

        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] << {
          has_parent: {
            parent_type: "project",
            query: {
              bool: project_query
            }
          }
        }

        query_hash
      end

      def project_ids_query(current_user, project_ids, public_and_internal_projects, feature = nil)
        conditions = []
        limit_private_projects = {}

        if project_ids != :any
          limit_private_projects[:filter] = { terms: { id: project_ids } }
        end

        if feature
          limit_private_projects[:must_not] = {
            term: { "#{feature}_access_level" => ProjectFeature::DISABLED }
          }
        end

        conditions << { bool: limit_private_projects } unless limit_private_projects.empty?

        if public_and_internal_projects
          conditions << if feature
                          {
                            bool: {
                              filter: [
                                { term: { visibility_level: Project::PUBLIC } },
                                { term: { "#{feature}_access_level" => ProjectFeature::ENABLED } }
                              ]
                            }
                          }
                        else
                          { term: { visibility_level: Project::PUBLIC } }
                        end

          if current_user
            conditions << if feature
                            {
                              bool: {
                                filter: [
                                  { term: { visibility_level: Project::INTERNAL } },
                                  { term: { "#{feature}_access_level" => ProjectFeature::ENABLED } }
                                ]
                              }
                            }
                          else
                            { term: { visibility_level: Project::INTERNAL } }
                          end
          end
        end

        { should: conditions }
      end
    end
  end
end
