require 'spec_helper'

describe 'admin Geo Nodes', :js do
  let!(:geo_node) { create(:geo_node) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    sign_in(create(:admin))
  end

  it 'show all public Geo Nodes and create new node link' do
    visit admin_geo_nodes_path
    wait_for_requests

    expect(page).to have_link('New node', href: new_admin_geo_node_path)
    page.within(find('.geo-node-item', match: :first)) do
      expect(page).to have_content(geo_node.url)
    end
  end

  describe 'create a new Geo Nodes' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit new_admin_geo_node_path
    end

    it 'creates a new Geo Node' do
      check 'This is a primary node'
      fill_in 'geo_node_url', with: 'https://test.gitlab.com'
      click_button 'Add Node'

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests

      page.within(find('.geo-node-item', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end

    it 'returns an error message when a duplicate primary is added' do
      create(:geo_node, :primary)

      check 'This is a primary node'
      fill_in 'geo_node_url', with: 'https://another-primary.example.com'
      click_button 'Add Node'

      expect(current_path).to eq admin_geo_nodes_path

      expect(page).to have_content('Primary node already exists')
    end
  end

  describe 'update an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
      page.within(find('.geo-node-actions', match: :first)) do
        page.click_link('Edit')
      end
    end

    it 'updates an existing Geo Node' do
      fill_in 'URL', with: 'http://newsite.com'
      check 'This is a primary node'
      click_button 'Save changes'

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests

      page.within(find('.geo-node-item', match: :first)) do
        expect(page).to have_content('http://newsite.com')
        expect(page).to have_content('Primary')
      end
    end
  end

  describe 'remove an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'removes an existing Geo Node' do
      page.within(find('.geo-node-actions', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove')
      end

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests
      expect(page).not_to have_css('.geo-node-item')
    end
  end
end
