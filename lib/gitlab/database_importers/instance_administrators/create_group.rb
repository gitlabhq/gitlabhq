# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module InstanceAdministrators
      class CreateGroup < ::BaseService
        include Stepable

        NAME = 'GitLab Instance'
        PATH_PREFIX = 'gitlab-instance'
        VISIBILITY_LEVEL = Gitlab::VisibilityLevel::INTERNAL

        steps :validate_application_settings,
          :validate_admins,
          :create_group,
          :save_group_id,
          :add_group_members,
          :track_event

        def initialize
          super(nil)
        end

        def execute
          execute_steps
        end

        private

        def validate_application_settings(result)
          return success(result) if application_settings

          log_error('No application_settings found')
          error(_('No application_settings found'))
        end

        def validate_admins(result)
          unless instance_admins.any?
            log_error('No active admin user found')
            return error(_('No active admin user found'))
          end

          success(result)
        end

        def create_group(result)
          if group_created?
            log_info(_('Instance administrators group already exists'))
            result[:group] = instance_administrators_group
            return success(result)
          end

          result[:group] = ::Groups::CreateService.new(instance_admins.first, create_group_params).execute

          if result[:group].persisted?
            success(result)
          else
            log_error("Could not create instance administrators group. Errors: %{errors}" % { errors: result[:group].errors.full_messages })
            error(_('Could not create group'))
          end
        end

        def save_group_id(result)
          return success(result) if group_created?

          response = application_settings.update(
            instance_administrators_group_id: result[:group].id
          )

          if response
            success(result)
          else
            log_error("Could not save instance administrators group ID, errors: %{errors}" % { errors: application_settings.errors.full_messages })
            error(_('Could not save group ID'))
          end
        end

        def add_group_members(result)
          group = result[:group]
          members = group.add_users(members_to_add(group), Gitlab::Access::MAINTAINER)
          errors = members.flat_map { |member| member.errors.full_messages }

          if errors.any?
            log_error('Could not add admins as members to self-monitoring project. Errors: %{errors}' % { errors: errors })
            error(_('Could not add admins as members'))
          else
            success(result)
          end
        end

        def track_event(result)
          ::Gitlab::Tracking.event("instance_administrators_group", "group_created", namespace: result[:group])

          success(result)
        end

        def group_created?
          instance_administrators_group.present?
        end

        def application_settings
          @application_settings ||= ApplicationSetting.current_without_cache
        end

        def instance_administrators_group
          application_settings.instance_administrators_group
        end

        def instance_admins
          @instance_admins ||= User.admins.active
        end

        def members_to_add(group)
          # Exclude admins who are already members of group because
          # `group.add_users(users)` returns an error if the users parameter contains
          # users who are already members of the group.
          instance_admins - group.members.collect(&:user)
        end

        def create_group_params
          {
            name: NAME,
            visibility_level: VISIBILITY_LEVEL,

            # The 8 random characters at the end are so that the path does not
            # clash with any existing group that the user might have created.
            path: "#{PATH_PREFIX}-#{SecureRandom.hex(4)}"
          }
        end
      end
    end
  end
end
