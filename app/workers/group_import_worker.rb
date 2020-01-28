# frozen_string_literal: true

class GroupImportWorker
  include ApplicationWorker
  include ExceptionBacktrace

  feature_category :importers

  def perform(user_id, group_id)
    current_user = User.find(user_id)
    group = Group.find(group_id)

    ::Groups::ImportExport::ImportService.new(group: group, user: current_user).execute
  end
end
