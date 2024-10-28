# frozen_string_literal: true

module Integrations
  class PropagateIntegrationDescendantWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :integrations
    urgency :low

    idempotent!

    def perform(integration_id, min_id, max_id)
      integration = Integration.find_by_id(integration_id)
      return unless integration&.class&.instance_specific?

      batch = Integration.descendants_from_self_or_ancestors_from(integration).id_in(min_id..max_id)

      Integrations::Propagation::BulkUpdateService.new(integration, batch).execute
    end
  end
end
