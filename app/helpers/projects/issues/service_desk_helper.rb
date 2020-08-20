# frozen_string_literal: true

module Projects::Issues::ServiceDeskHelper
  def service_desk_meta(project)
    empty_state_meta = {
      is_service_desk_supported: Gitlab::ServiceDesk.supported?,
      is_service_desk_enabled: project.service_desk_enabled?,
      can_edit_project_settings: can?(current_user, :admin_project, project)
    }

    if Gitlab::ServiceDesk.supported?
      empty_state_meta.merge(supported_meta(project))
    else
      empty_state_meta.merge(unsupported_meta(project))
    end
  end

  private

  def supported_meta(project)
    {
      service_desk_address: project.service_desk_address,
      service_desk_help_page: help_page_path('user/project/service_desk'),
      edit_project_page: edit_project_path(project),
      svg_path: image_path('illustrations/service_desk_empty.svg')
    }
  end

  def unsupported_meta(project)
    {
      incoming_email_help_page: help_page_path('administration/incoming_email', anchor: 'set-it-up'),
      svg_path: image_path('illustrations/service-desk-setup.svg')
    }
  end
end
