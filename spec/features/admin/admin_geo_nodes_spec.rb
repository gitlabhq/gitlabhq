require 'spec_helper'

RSpec.describe 'admin Geo Nodes', type: :feature do
  let!(:geo_node) { create(:geo_node) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    sign_in(create(:admin))
  end

  it 'show all public Geo Nodes' do
    visit admin_geo_nodes_path

    page.within(find('.geo-nodes', match: :first)) do
      expect(page).to have_content(geo_node.url)
    end
  end

  describe 'create a new Geo Nodes' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit admin_geo_nodes_path
    end

    it 'creates a new Geo Node' do
      check 'This is a primary node'
      fill_in 'geo_node_url', with: 'https://test.gitlab.com'
      fill_in 'geo_node_geo_node_key_attributes_key', with: new_ssh_key
      click_button 'Add Node'

      expect(current_path).to eq admin_geo_nodes_path

      page.within(find('.geo-nodes', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end
  end

  describe 'update an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      page.within(find('.node-actions', match: :first)) do
        page.click_link('Edit')
      end
    end

    it 'updates an existing Geo Node' do
      fill_in 'URL', with: 'http://newsite.com'
      check 'This is a primary node'
      click_button 'Save changes'

      expect(current_path).to eq admin_geo_nodes_path

      page.within(find('.geo-nodes', match: :first)) do
        expect(page).to have_content('http://newsite.com')
        expect(page).to have_content('Primary')
      end
    end
  end

  describe 'remove an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
    end

    it 'removes an existing Geo Node' do
      page.within(find('.node-actions', match: :first)) do
        page.click_link('Remove')
      end

      expect(current_path).to eq admin_geo_nodes_path
      expect(page).not_to have_css('.geo-nodes')
    end
  end
end
