# frozen_string_literal: true

class Import::GitlabGroupsController < ApplicationController
  include WorkhorseAuthorization

  before_action :check_import_rate_limit!, only: %i[create]

  feature_category :importers
  urgency :low

  def create
    unless file_is_valid?(group_params[:file])
      return redirect_to new_group_path(anchor: 'import-group-pane'),
        alert: s_('GroupImport|Unable to process group import file')
    end

    group_data = group_params
      .except(:file)
      .merge(
        visibility_level: closest_allowed_visibility_level,
        import_export_upload: ImportExportUpload.new(import_file: group_params[:file], user: current_user)
      )
      .with_defaults(organization_id: Current.organization_id)

    response = ::Groups::CreateService.new(current_user, group_data).execute

    group = response[:group]

    if response.success?
      if Groups::ImportExport::ImportService.new(group: group, user: current_user).async_execute
        redirect_to(
          group_path(group),
          notice: s_("GroupImport|Group '%{group_name}' is being imported.") % { group_name: group.name }
        )
      else
        redirect_to group_path(group), alert: _("Group import could not be scheduled")
      end
    else
      redirect_to new_group_path(anchor: 'import-group-pane'),
        alert: s_("GroupImport|Group could not be imported: %{errors}") % {
          errors: group.errors.full_messages.to_sentence
        }
    end
  end

  private

  def group_params
    params.permit(:path, :name, :parent_id, :file)
  end

  def closest_allowed_visibility_level
    if group_params[:parent_id].present?
      parent_group = Group.find(group_params[:parent_id])

      Gitlab::VisibilityLevel.closest_allowed_level(parent_group.visibility_level)
    else
      Gitlab::VisibilityLevel::PRIVATE
    end
  end

  def check_import_rate_limit!
    check_rate_limit!(:group_import, scope: current_user) do
      redirect_to new_group_path, alert: _('This endpoint has been requested too many times. Try again later.')
    end
  end

  def uploader_class
    ImportExportUploader
  end

  def maximum_size
    Gitlab::CurrentSettings.max_import_size.megabytes
  end
end
