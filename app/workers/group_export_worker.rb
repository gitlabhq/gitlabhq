# frozen_string_literal: true

class GroupExportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  include ExceptionBacktrace

  feature_category :importers
  loggable_arguments 2
  sidekiq_options retry: false, dead: false

  def perform(current_user_id, group_id, params = {})
    current_user = User.find(current_user_id)
    group = Group.find(group_id)

    ::Groups::ImportExport::ExportService.new(group: group, user: current_user, params: params).execute
  end
end
