# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Repository settings' do
  include WaitForRequests

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'Deploy tokens' do
    let!(:deploy_token) { create(:deploy_token, :group, groups: [group]) }

    before do
      stub_container_registry_config(enabled: true)
      visit group_settings_repository_path(group)
    end

    it_behaves_like 'a deploy token in settings' do
      let(:entity_type) { 'group' }
    end
  end

  context 'Default initial branch name' do
    before do
      visit group_settings_repository_path(group)
    end

    it 'has the setting section' do
      expect(page).to have_css("#js-default-branch-name")
    end

    it 'renders the correct setting section content' do
      within("#js-default-branch-name") do
        expect(page).to have_content("Default initial branch name")
        expect(page).to have_content("The default name for the initial branch of new repositories created in the group.")
      end
    end
  end
end
