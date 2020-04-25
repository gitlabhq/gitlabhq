# frozen_string_literal: true

class GroupImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: false
  feature_category :importers

  def perform(user_id, group_id)
    current_user = User.find(user_id)
    group = Group.find(group_id)
    group_import = group.build_import_state(jid: self.jid)

    group_import.start!

    ::Groups::ImportExport::ImportService.new(group: group, user: current_user).execute

    group_import.finish!
  rescue StandardError => e
    group_import&.fail_op(e.message)

    raise e
  end
end
