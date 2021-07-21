# frozen_string_literal: true

class DisallowTwoFactorForSubgroupsWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  INTERVAL = 2.seconds.to_i

  feature_category :subgroups
  tags :exclude_from_kubernetes
  idempotent!

  def perform(group_id)
    begin
      group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    # rubocop: disable CodeReuse/ActiveRecord
    subgroups = group.descendants.where(require_two_factor_authentication: true) # rubocop: disable CodeReuse/ActiveRecord
    subgroups.find_each(batch_size: 100).with_index do |subgroup, index|
      delay = index * INTERVAL

      with_context(namespace: subgroup) do
        DisallowTwoFactorForGroupWorker.perform_in(delay, subgroup.id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
