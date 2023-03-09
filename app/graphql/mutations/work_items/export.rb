# frozen_string_literal: true

module Mutations
  module WorkItems
    class Export < BaseMutation
      graphql_name 'WorkItemExport'

      include FindsProject
      include ::WorkItems::SharedFilterArguments
      include ::SearchArguments

      authorize :export_work_items

      argument :project_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Full project path.'

      argument :selected_fields,
        [::Types::WorkItems::AvailableExportFieldsEnum],
        required: false,
        description: 'List of selected fields to be exported. Omit to export all available fields.'

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(project_path)

        check_export_available_for!(project)

        # rubocop:disable CodeReuse/Worker
        IssuableExportCsvWorker.perform_async(:work_item, current_user.id, project.id, args)
        # rubocop:enable CodeReuse/Worker

        {
          errors: []
        }
      end

      def check_export_available_for!(project)
        return if Feature.enabled?(:import_export_work_items_csv, project)

        error = '`import_export_work_items_csv` feature flag is disabled.'

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, error
      end
    end
  end
end
