# frozen_string_literal: true

class GroupExportWorker
  include ApplicationWorker
  include ExceptionBacktrace

  feature_category :source_code_management

  def perform(current_user_id, group_id, params = {})
    current_user = User.find(current_user_id)
    group        = Group.find(group_id)

    ::Groups::ImportExport::ExportService.new(group: group, user: current_user, params: params).execute
  end
end
