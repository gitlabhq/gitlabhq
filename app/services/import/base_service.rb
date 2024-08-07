# frozen_string_literal: true

module Import
  class BaseService < ::BaseService
    def initialize(client, user, params)
      @client = client
      @current_user = user
      @params = params
    end

    def authorized?
      can?(current_user, :import_projects, target_namespace)
    end

    private

    def find_or_create_namespace(namespace, owner)
      namespace = params[:target_namespace].presence || namespace

      return current_user.namespace if namespace == owner

      group = Groups::NestedCreateService.new(
        current_user,
        organization_id: params[:organization_id],
        group_path: namespace
      ).execute

      group.errors.any? ? current_user.namespace : group
    rescue StandardError => e
      Gitlab::AppLogger.error(e)

      current_user.namespace
    end

    def project_save_error(project)
      project.errors.full_messages.join(', ')
    end

    def success(project, warning: nil)
      super().merge(project: project, status: :success, warning: warning)
    end

    def track_access_level(import_type)
      Gitlab::Tracking.event(
        self.class.name,
        'create',
        label: 'import_access_level',
        user: current_user,
        extra: { user_role: user_role, import_type: import_type }
      )
    end

    def user_role
      if current_user.id == target_namespace.owner_id
        'Owner'
      else
        access_level = current_user&.group_members&.find_by(source_id: target_namespace.id)&.access_level

        case access_level
        when nil
          'Not a member'
        else
          Gitlab::Access.human_access(access_level)
        end
      end
    end
  end
end
