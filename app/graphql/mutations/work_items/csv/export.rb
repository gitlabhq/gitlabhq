# frozen_string_literal: true

module Mutations
  module WorkItems
    module CSV
      class Export < BaseMutation
        graphql_name 'WorkItemsCsvExport'

        include FindsProject
        include ::SearchArguments
        include ::WorkItems::SharedFilterArguments

        authorize :export_work_items

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full project path.'

        argument :selected_fields, [::Types::WorkItems::AvailableExportFieldsEnum],
          required: false,
          description: 'List of selected fields to be exported. Omit to export all available fields.'

        field :message, GraphQL::Types::String,
          null: true,
          description: 'Export request result message.'

        def resolve(args)
          project_path = args.delete(:project_path)
          project = authorized_find!(project_path)

          check_export_available_for!(project)

          # This is some old code, moved to a different module. We should definitely seek to move this code
          # to a service class.
          # rubocop:disable CodeReuse/Worker -- see above
          IssuableExportCsvWorker.perform_async(:work_item, current_user.id, project.id, prepare_finder_params(args))
          # rubocop:enable CodeReuse/Worker

          {
            message: format(
              _('Your CSV export request has succeeded. The result will be emailed to %{email}.'),
              { email: current_user.notification_email_or_default }
            ),
            errors: []
          }
        end

        def check_export_available_for!(project)
          return if project.work_items_project_issues_list_feature_flag_enabled?

          error = '`work_items_project_issues_list` feature flag is disabled.'

          raise_resource_not_available_error! error
        end
      end
    end
  end
end

Mutations::WorkItems::CSV::Export.prepend_mod
