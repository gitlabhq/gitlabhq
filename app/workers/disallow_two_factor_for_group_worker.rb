# frozen_string_literal: true

class DisallowTwoFactorForGroupWorker
  include ApplicationWorker
  include ExceptionBacktrace

  feature_category :subgroups
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
