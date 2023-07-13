# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Projects::ObservabilityHelper, type: :helper, feature_category: :tracing do
  describe '#observability_tracing_view_model' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:project) { build_stubbed(:project, group: group) }

    it 'generates the correct JSON' do
      expected_json = {
        tracingUrl: Gitlab::Observability.tracing_url(project),
        provisioningUrl: Gitlab::Observability.provisioning_url(project),
        oauthUrl: Gitlab::Observability.oauth_url
      }.to_json

      expect(helper.observability_tracing_view_model(project)).to eq(expected_json)
    end
  end
end
