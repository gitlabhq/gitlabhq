# frozen_string_literal: true

class DisallowTwoFactorForGroupWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :groups_and_projects
  idempotent!

  def perform(group_id)
    begin
      group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    group.update!(require_two_factor_authentication: false)
  end
end
