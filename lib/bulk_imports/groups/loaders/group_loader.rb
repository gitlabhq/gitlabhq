# frozen_string_literal: true

module BulkImports
  module Groups
    module Loaders
      class GroupLoader
        TWO_FACTOR_KEY = 'require_two_factor_authentication'

        GroupCreationError = Class.new(StandardError)

        def load(context, data)
          path = data['path']
          current_user = context.current_user
          destination_namespace = context.entity.destination_namespace
          organization = context.entity.bulk_import.organization

          raise(GroupCreationError, 'Path is missing') unless path.present?
          raise(GroupCreationError, 'Destination is not a group') if user_namespace_destination?(destination_namespace)
          raise(GroupCreationError, 'User not allowed to create group') unless user_can_create_group?(current_user, data)
          raise(GroupCreationError, 'Group exists') if group_exists?(organization, destination_namespace, path)

          unless two_factor_requirements_met?(current_user, data)
            raise(GroupCreationError, 'User requires Two-Factor Authentication')
          end

          data['organization_id'] = organization_id(organization, destination_namespace, current_user)

          response = ::Groups::CreateService.new(current_user, data).execute
          group = response[:group]

          raise(GroupCreationError, group.errors.full_messages.to_sentence) if response.error?

          context.entity.update!(group: group, organization: nil)

          group
        end

        private

        def organization_id(organization, destination_namespace, user)
          dest = destination(organization, destination_namespace)

          if dest
            dest.organization_id
          else
            user.namespace.organization_id
          end
        end

        # Scope the destination lookup to the import's organization so a same-path
        # namespace in another organization cannot be resolved as the destination.
        def destination(organization, path)
          organization.namespaces.find_by_full_path(path)
        end

        def user_can_create_group?(current_user, data)
          if data['parent_id']
            parent = Namespace.find_by_id(data['parent_id'])

            Ability.allowed?(current_user, :create_subgroup, parent)
          else
            Ability.allowed?(current_user, :create_group)
          end
        end

        def two_factor_requirements_met?(current_user, data)
          return true unless data.has_key?(TWO_FACTOR_KEY) && data[TWO_FACTOR_KEY]

          current_user.two_factor_enabled?
        end

        def group_exists?(organization, destination_namespace, path)
          full_path = destination_namespace.present? ? File.join(destination_namespace, path) : path

          organization.groups.find_by_full_path(full_path).present?
        end

        # Not org-scoped: a personal namespace is user-global (typically in the
        # default organization), and this guard checks the destination *type* to
        # reject importing a group into a personal namespace. Scoping it would let
        # an out-of-org personal-namespace path slip past the guard.
        def user_namespace_destination?(destination_namespace)
          return false unless destination_namespace.present?

          Namespace.find_by_full_path(destination_namespace)&.user_namespace?
        end
      end
    end
  end
end
