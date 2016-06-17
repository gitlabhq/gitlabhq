module Elastic
  module NotesSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings do
        indexes :id,          type: :integer
        indexes :note,        type: :string,
                              index_options: 'offsets'
        indexes :project_id,  type: :integer
        indexes :created_at,  type: :date

        indexes :issue do
          indexes :assignee_id, type: :integer
          indexes :author_id, type: :integer
          indexes :confidential, type: :boolean
        end

        indexes :updated_at_sort, type: :string, index: 'not_analyzed'
      end

      def as_indexed_json(options = {})
        data = {}

        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        [:id, :note, :project_id, :created_at].each do |attr|
          data[attr.to_s] = self.send(attr)
        end

        if noteable.is_a?(Issue)
          data['issue'] = {
            assignee_id: noteable.assignee_id,
            author_id: noteable.author_id,
            confidential: noteable.confidential
          }
        end

        data['updated_at_sort'] = updated_at
        data
      end

      def self.elastic_search(query, options: {})
        options[:in] = ['note']

        query_hash = {
          query: {
            bool: {
              must: [{ match: { note: query } }],
            },
          }
        }

        if query.blank?
          query_hash[:query][:bool][:must] = [{ match_all: {} }]
          query_hash[:track_scores] = true
        end

        query_hash = project_ids_filter(query_hash, options[:project_ids])
        query_hash = confidentiality_filter(query_hash, options[:current_user])

        query_hash[:sort] = [
          { updated_at_sort: { order: :desc, mode: :min } },
          :_score
        ]

        query_hash[:highlight] = highlight_options(options[:in])

        self.__elasticsearch__.search(query_hash)
      end

      def self.confidentiality_filter(query_hash, current_user)
        return query_hash if current_user && current_user.admin?

        filter = {
          bool: {
            should: [
              { bool: { must_not: [{ exists: { field: :issue } }] } },
              { term: { "issue.confidential" => false } }
            ]
          }
        }

        if current_user
          filter[:bool][:should] << {
            bool: {
              must: [
                { term: { "issue.confidential" => true } },
                { bool: {
                    should: [
                      { term: { "issue.author_id" => current_user.id } },
                      { term: { "issue.assignee_id" => current_user.id } },
                      { terms: { "project_id" => current_user.authorized_projects(Gitlab::Access::REPORTER).pluck(:id) } }
                    ]
                  }
                }
              ]
            }
          }
        end

        query_hash[:query][:bool][:must] << filter
        query_hash
      end
    end
  end
end
