# frozen_string_literal: true

module Ci
  class UpdateGroupPendingBuildService
    BATCH_SIZE = 500
    BATCH_QUIET_PERIOD = 2.seconds

    def initialize(group, update_params)
      @group = group
      @update_params = update_params.symbolize_keys
    end

    def execute
      Ci::UpdatePendingBuildService.new(@group, @update_params).execute

      @group.descendants.each_batch(of: BATCH_SIZE) do |subgroups|
        subgroups.each do |subgroup|
          Ci::UpdatePendingBuildService.new(subgroup, update_params_for_group(subgroup)).execute
        end

        sleep BATCH_QUIET_PERIOD
      end
    end

    private

    def update_params_for_group(group)
      # Update the params with an eventual updated version from Ci::PendingBuild.namespace_transfer_params
      transfer_params = Ci::PendingBuild.namespace_transfer_params(group)
      @update_params.merge(transfer_params.slice(*@update_params.keys))
    end
  end
end
