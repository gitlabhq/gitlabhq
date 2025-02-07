# frozen_string_literal: true

module Pages
  class UpdateService < BaseService
    include Gitlab::Allowable

    def execute
      unless can_update_page_settings?
        return ServiceResponse.error(message: _('The current user is not authorized to update the page settings'),
          reason: :forbidden)
      end

      Project.transaction do
        update_pages_https_only!
        update_pages_project_settings!
      end

      ServiceResponse.success(payload: { project: project })
    end

    private

    def update_pages_project_settings!
      pages_project_settings = params.slice(:pages_unique_domain_enabled, :pages_primary_domain)
      return if pages_project_settings.empty?

      project.project_setting.update!(pages_project_settings)
    end

    def update_pages_https_only!
      return unless params.key?(:pages_https_only)

      project.update!(pages_https_only: params[:pages_https_only])
    end

    def can_update_page_settings?
      can?(current_user, :update_pages, project)
    end
  end
end
