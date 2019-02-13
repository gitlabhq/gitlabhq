# frozen_string_literal: true

module API
  class IssuableBulkUpdate < Grape::API
    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      %w(issue merge_request).each do |issuable|
        desc "Updates a list of #{issuable.pluralize}" do
          detail 'This feature was introduced in 11.9'
        end
        params do
          optional :state_event, type: String, values: %w(reopen close), desc: 'Reopens or closes a resource'
          optional :milestone_id, type: Integer, desc: 'The milestone ID number'
          optional :add_label_ids, type: Array[Integer], desc: 'IDs of labels to be added'
          optional :remove_label_ids, type: Array[Integer], desc: 'IDs of labels to be removed'
          optional :subscription_event, type: String, values: %w(subscribe unsubscribe),
                                        desc: 'Subscribes or unsubscribes from a resource'

          if issuable == 'issue'
            optional :assignee_ids, type: Array[Integer], desc: 'List of assignees IDs'
            at_least_one_of :state_event, :milestone_id, :add_label_ids, :remove_label_ids,
                            :subscription_event, :assignee_ids
          else
            optional :assignee_id, type: Integer, desc: 'ID of the assignee'
            at_least_one_of :state_event, :milestone_id, :add_label_ids, :remove_label_ids,
                            :subscription_event, :assignee_id
          end
        end
        put ":id/#{issuable}/bulk_update" do
          update_params = declared_params(include_missing: false)

          result = Issuable::BulkUpdateService.new(user_project, current_user, update_params)
            .execute(issuable)
          quantity = result[:count]

          if result[:success]
            status 200
            { notice: "#{quantity} #{issuable.pluralize(quantity)} updated" }
          else
            render_api_error!('Bulk update failed', 400)
          end
        end
      end
    end
  end
end
