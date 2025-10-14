# frozen_string_literal: true

module Mutations
  module WorkItems
    module CSV
      class Import < BaseMutation
        graphql_name 'WorkItemsCsvImport'

        include FindsProject

        EXTENSION_ALLOWLIST = %w[csv].map(&:downcase).freeze

        authorize :import_work_items

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full project path.'

        argument :file, ApolloUploadServer::Upload,
          required: true,
          description: 'CSV file to import work items from.'

        field :message, GraphQL::Types::String,
          null: true,
          description: 'Import request result message.'

        def resolve(args)
          project_path = args.delete(:project_path)
          project = authorized_find!(project_path)

          file = args[:file]

          unless file_is_valid?(file)
            return {
              message: nil,
              errors: [invalid_file_message]
            }
          end

          result = ::WorkItems::PrepareImportCsvService.new(project, current_user, file:).execute

          return { message: result.message, errors: [] } if result.success?

          { message: nil, errors: [result.message] }
        end

        private

        def file_is_valid?(file)
          return false unless file.respond_to?(:original_filename)

          file_extension = File.extname(file.original_filename).downcase.delete('.')
          EXTENSION_ALLOWLIST.include?(file_extension)
        end

        def invalid_file_message
          supported_file_extensions = ".#{EXTENSION_ALLOWLIST.join(', .')}"
          format(_("The uploaded file was invalid. Supported file extensions are %{extensions}."),
            { extensions: supported_file_extensions })
        end
      end
    end
  end
end
