# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Repository settings', :js, feature_category: :source_code_management do
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, owners: user) }

  before do
    sign_in(user)
  end

  context 'Deploy tokens' do
    let!(:deploy_token) { create(:deploy_token, :group, groups: [group]) }

    before do
      stub_container_registry_config(enabled: true)
    end

    it_behaves_like 'a deploy token in settings' do
      let(:entity_type) { 'group' }
      let(:page_path) { group_settings_repository_path(group) }
    end
  end

  context 'Default branch' do
    before do
      visit group_settings_repository_path(group)
    end

    it 'has the setting section' do
      expect(page).to have_css("#js-default-branch-name")
    end

    it 'renders the correct setting section content' do
      within("#js-default-branch-name") do
        expect(page).to have_content("Default branch")
        expect(page).to have_content("Set the initial name and protections for the default branch of new repositories created in the group.")
      end
    end
  end
end
