# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }

  describe '#organization_show_app_data' do
    before do
      allow(helper).to receive(:groups_and_projects_organization_path)
        .with(organization)
        .and_return('/-/organizations/default/groups_and_projects')
    end

    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(
          helper.organization_show_app_data(organization)
        )
      ).to eq(
        {
          'organization' => { 'id' => organization.id, 'name' => organization.name },
          'groups_and_projects_organization_path' => '/-/organizations/default/groups_and_projects'
        }
      )
    end
  end
end
