# frozen_string_literal: true

module Import
  class BaseService < ::BaseService
    def initialize(client, user, params)
      @client = client
      @current_user = user
      @params = params
    end

    private

    def find_or_create_namespace(namespace, owner)
      namespace = params[:target_namespace].presence || namespace

      return current_user.namespace if namespace == owner

      group = Groups::NestedCreateService.new(current_user, group_path: namespace).execute

      group.errors.any? ? current_user.namespace : group
    rescue StandardError => e
      Gitlab::AppLogger.error(e)

      current_user.namespace
    end

    def project_save_error(project)
      project.errors.full_messages.join(', ')
    end

    def success(project)
      super().merge(project: project, status: :success)
    end
  end
end
