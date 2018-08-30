module Elastic
  module ApplicationSearch
    extend ActiveSupport::Concern

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
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id)
        end
      end

      after_commit on: :update do
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(
            :update,
            self.class.to_s,
            self.id,
            changed_fields: self.previous_changes.keys
          )
        end
      end

      after_commit on: :destroy do
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
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
        send(attr_name) # rubocop:disable GitlabSecurity/PublicSend
      rescue => err
        logger.warn("Elasticsearch failed to read #{attr_name} for #{self.class} #{self.id}: #{err}")
        nil
      end
    end

    class_methods do
      # Should be overridden for all nested models
      def nested?
        false
      end

      def highlight_options(fields)
        es_fields = fields.map { |field| field.split('^').first }.each_with_object({}) do |field, memo|
          memo[field.to_sym] = {}
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

      # Builds an elasticsearch query that will select child documents from a
      # set of projects, taking user access rules into account.
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

      # Builds an elasticsearch query that will select projects the user is
      # granted access to.
      #
      # If a project feature is specified, it indicates interest in child
      # documents gated by that project feature - e.g., "issues". The feature's
      # visibility level must be taken into account.
      def project_ids_query(user, project_ids, public_and_internal_projects, feature = nil)
        # When reading cross project is not allowed, only allow searching a
        # a single project, so the `:read_*` ability is only checked once.
        unless Ability.allowed?(user, :read_cross_project)
          project_ids = [] if project_ids.is_a?(Array) && project_ids.size > 1
        end

        # At least one condition must be present, so pick no projects for
        # anonymous users.
        # Pick private, internal and public projects the user is a member of.
        # Pick all private projects for admins & auditors.
        conditions = [pick_projects_by_membership(project_ids, feature)]

        if public_and_internal_projects
          # Skip internal projects for anonymous and external users.
          # Others are given access to all internal projects. Admins & auditors
          # get access to internal projects where the feature is private.
          conditions << pick_projects_by_visibility(Project::INTERNAL, user, feature) if user && !user.external?

          # All users, including anonymous, can access public projects.
          # Admins & auditors get access to public projects where the feature is
          # private.
          conditions << pick_projects_by_visibility(Project::PUBLIC, user, feature)
        end

        { should: conditions }
      end

      private

      # Most users come with a list of projects they are members of, which may
      # be a mix of public, internal or private. Grant access to them all, as
      # long as the project feature is not disabled.
      #
      # Admins & auditors are given access to all private projects. Access to
      # internal or public projects where the project feature is private is not
      # granted here.
      def pick_projects_by_membership(project_ids, feature = nil)
        condition =
          if project_ids == :any
            { term: { visibility_level: Project::PRIVATE } }
          else
            { terms: { id: project_ids } }
          end

        limit_by_feature(condition, feature, include_members_only: true)
      end

      # Grant access to projects of the specified visibility level to the user.
      #
      # If a project feature is specified, access is only granted if the feature
      # is enabled or, for admins & auditors, private.
      def pick_projects_by_visibility(visibility, user, feature)
        condition = { term: { visibility_level: visibility } }

        limit_by_feature(condition, feature, include_members_only: user&.full_private_access?)
      end

      # If a project feature is specified, access is dependent on its visibility
      # level being enabled (or private if `include_members_only: true`).
      #
      # This method is a no-op if no project feature is specified.
      #
      # Always denies access to projects when the feature is disabled - even to
      # admins & auditors - as stale child documents may be present.
      def limit_by_feature(condition, feature, include_members_only:)
        return condition unless feature

        limit =
          if include_members_only
            { terms: { "#{feature}_access_level" => [ProjectFeature::ENABLED, ProjectFeature::PRIVATE] } }
          else
            { term: { "#{feature}_access_level" => ProjectFeature::ENABLED } }
          end

        { bool: { filter: [condition, limit] } }
      end
    end
  end
end
