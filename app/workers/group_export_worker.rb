# frozen_string_literal: true

class GroupExportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  include ExceptionBacktrace

  feature_category :importers
  loggable_arguments 2
  sidekiq_options retry: false, dead: false

  def perform(current_user_id, group_id, params = {})
    current_user = User.find_by_id(current_user_id)
    return unless current_user

    group = Group.find_by_id(group_id)
    return unless group

    params.symbolize_keys!

    ::Groups::ImportExport::ExportService.new(
      group: group,
      user: current_user,
      exported_by_admin: params.delete(:exported_by_admin),
      params: params
    ).execute
  end
end
