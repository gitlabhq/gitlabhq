require 'spec_helper'

describe 'GEO Nodes' do
  include ::EE::GeoHelpers

  set(:user) { create(:user) }
  set(:geo_primary) { create(:geo_node, :primary) }
  set(:geo_secondary) { create(:geo_node) }

  context 'Geo Secondary Node' do
    let(:project) { create(:project) }

    before do
      stub_current_geo_node(geo_secondary)

      project.add_maintainer(user)
      sign_in(user)
    end

    describe "showing Flash Info Message" do
      it 'on dashboard' do
        visit root_dashboard_path
        expect(page).to have_content 'You are on a secondary, read-only Geo node. If you want to make changes, you must visit this page on the primary node.'
      end

      it 'on project overview' do
        visit project_path(project)
        expect(page).to have_content 'You are on a secondary, read-only Geo node. If you want to make changes, you must visit this page on the primary node.'
      end
    end
  end

  context 'Primary Geo Node' do
    let(:admin_user) { create(:user, :admin) }

    before do
      stub_current_geo_node(geo_primary)
      stub_licensed_features(geo: true)

      sign_in(admin_user)
    end

    describe 'Geo Nodes admin screen' do
      it "has a 'Open projects' button on listed secondary geo nodes pointing to correct URL", :js do
        visit admin_geo_nodes_path

        expect(page).to have_content(geo_primary.url)
        expect(page).to have_content(geo_secondary.url)

        wait_for_requests

        geo_node_actions = all('div.geo-node-actions')
        expected_url = File.join(geo_secondary.url, '/admin/geo/projects')

        expect(geo_node_actions.last).to have_link('Open projects', href: expected_url)
      end
    end
  end
end
