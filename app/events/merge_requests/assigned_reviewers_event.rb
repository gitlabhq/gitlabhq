# frozen_string_literal: true

module MergeRequests
  class AssignedReviewersEvent < Gitlab::EventStore::CloudEvent
    extend ::Gitlab::Utils::Override

    event_category :merge_requests
    event_type :assigned_reviewers

    class << self
      def build(current_user:, merge_request:, new_reviewers:)
        build_cloud_event(
          source: "projects/#{merge_request.project.id}",
          subject: "merge_requests/#{merge_request.id}",
          current_user: current_user,
          organization: merge_request.project.organization,
          event_data: generate_event_data(merge_request, new_reviewers)
        )
      end

      private

      def generate_event_data(merge_request, new_reviewers)
        {
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id,
          new_reviewers: new_reviewers.map { |reviewer| { id: reviewer.id, user_type: reviewer.user_type } }
        }
      end
    end

    def data_schema
      {
        type: "object",
        required: %w[
          merge_request_id
          merge_request_iid
          project_id
          new_reviewers
        ],
        properties: {
          merge_request_id: {
            type: "integer"
          },
          merge_request_iid: {
            type: "integer"
          },
          project_id: {
            type: "integer"
          },
          new_reviewers: {
            type: "array",
            items: {
              type: "object",
              required: %w[id user_type],
              properties: {
                id: {
                  type: "integer"
                },
                user_type: {
                  type: "string"
                }
              }
            }
          }
        },
        additionalProperties: false
      }
    end
  end
end
