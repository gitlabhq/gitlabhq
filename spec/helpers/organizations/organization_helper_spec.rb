# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }

  describe '#organization_show_app_data' do
    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(
          helper.organization_show_app_data(organization)
        )
      ).to eq({ 'organization' => { 'id' => organization.id, 'name' => organization.name } })
    end
  end
end
