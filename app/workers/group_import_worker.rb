# frozen_string_literal: true

class GroupImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: false, dead: false
  feature_category :importers

  def perform(user_id, group_id)
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464675')

    current_user = User.find(user_id)
    group = Group.find(group_id)
    group_import_state = group.import_state

    group_import_state.jid = self.jid
    group_import_state.start!

    ::Groups::ImportExport::ImportService.new(group: group, user: current_user).execute

    group_import_state.finish!
  rescue StandardError => e
    group_import_state&.fail_op(e.message)

    raise e
  end
end
