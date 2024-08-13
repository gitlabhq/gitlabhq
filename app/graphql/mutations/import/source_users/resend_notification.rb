# frozen_string_literal: true

module Mutations
  module Import
    module SourceUsers
      class ResendNotification < BaseMutation
        graphql_name 'ImportSourceUserResendNotification'

        argument :id, Types::GlobalIDType[::Import::SourceUser],
          required: true,
          description: 'Global ID of the mapping of a user on source instance to a user on destination instance.'

        field :import_source_user,
          Types::Import::SourceUserType,
          null: true,
          description: 'Mapping of a user on source instance to a user on destination instance after mutation.'

        authorize :admin_import_source_user

        def resolve(args)
          if Feature.disabled?(:importer_user_mapping, current_user)
            raise_resource_not_available_error! '`importer_user_mapping` feature flag is disabled.'
          end

          import_source_user = authorized_find!(id: args[:id])

          verify_rate_limit!(import_source_user)

          result = ::Import::SourceUsers::ResendNotificationService.new(import_source_user, current_user: current_user)
            .execute

          { import_source_user: result.payload, errors: result.errors }
        end

        private

        def verify_rate_limit!(import_source_user)
          return unless Gitlab::ApplicationRateLimiter.throttled?(
            :import_source_user_notification, scope: [import_source_user]
          )

          raise_resource_not_available_error! _('This endpoint has been requested too many times. Try again later.')
        end
      end
    end
  end
end
