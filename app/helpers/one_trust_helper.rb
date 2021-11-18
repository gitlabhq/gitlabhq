# frozen_string_literal: true

module OneTrustHelper
  def one_trust_enabled?
    Feature.enabled?(:ecomm_instrumentation, type: :ops) &&
      Gitlab.config.extra.has_key?('one_trust_id') &&
      Gitlab.config.extra.one_trust_id.present?
  end
end
