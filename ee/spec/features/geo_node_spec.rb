require 'spec_helper'

describe 'GEO Nodes' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:geo_url) { 'http://geo.example.com' }

  context 'Geo Secondary Node' do
    before do
      allow(Gitlab::Geo).to receive(:secondary?) { true }
      allow(Gitlab::Geo).to receive_message_chain(:primary_node, :url) { geo_url }

      project.add_master(user)
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
end
