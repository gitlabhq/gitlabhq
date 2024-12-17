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

          raise(GroupCreationError, 'Path is missing') unless path.present?
          raise(GroupCreationError, 'Destination is not a group') if user_namespace_destination?(destination_namespace)
          raise(GroupCreationError, 'User not allowed to create group') unless user_can_create_group?(current_user, data)
          raise(GroupCreationError, 'Group exists') if group_exists?(destination_namespace, path)

          unless two_factor_requirements_met?(current_user, data)
            raise(GroupCreationError, 'User requires Two-Factor Authentication')
          end

          data['organization_id'] = organization_id(destination_namespace, current_user)

          response = ::Groups::CreateService.new(current_user, data).execute
          group = response[:group]

          raise(GroupCreationError, group.errors.full_messages.to_sentence) if response.error?

          context.entity.update!(group: group, organization: nil)

          group
        end

        private

        def organization_id(destination_namespace, user)
          if destination(destination_namespace)
            destination(destination_namespace).organization_id
          else
            user.namespace.organization_id
          end
        end

        def destination(path)
          Namespace.find_by_full_path(path)
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

        def group_exists?(destination_namespace, path)
          full_path = destination_namespace.present? ? File.join(destination_namespace, path) : path

          Group.find_by_full_path(full_path).present?
        end

        def user_namespace_destination?(destination_namespace)
          return false unless destination_namespace.present?

          destination(destination_namespace)&.user_namespace?
        end
      end
    end
  end
end
