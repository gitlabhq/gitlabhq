# frozen_string_literal: true

module API
  class GroupPlaceholderReassignments < ::API::Base
    before do
      authenticate!
      not_found! unless Feature.enabled?(:importer_user_mapping_reassignment_csv, current_user)
      forbidden! unless can?(current_user, :owner_access, user_group)
    end

    feature_category :importers

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the list of pending placeholder assignments for a group' do
        detail 'This feature was added in GitLab 17.10'
        success code: 200
      end
      get ':id/placeholder_reassignments' do
        csv_response = Import::SourceUsers::GenerateCsvService.new(user_group, current_user: current_user).execute

        if csv_response.success?
          content_type 'text/csv; charset=utf-8'
          header(
            "Content-Disposition",
            "attachment; filename=\"placeholder_reassignments_for_group_#{user_group.id}_#{Time.current.to_i}.csv\""
          )
          env['api.format'] = :csv
          csv_response.payload
        else
          unprocessable_entity!(csv_response.message)
        end
      end
    end
  end
end
