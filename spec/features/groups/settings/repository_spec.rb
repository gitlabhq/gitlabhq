# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Repository settings', :js do
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  context 'Deploy tokens' do
    let!(:deploy_token) { create(:deploy_token, :group, groups: [group]) }

    before do
      stub_container_registry_config(enabled: true)
    end

    context 'when ajax deploy tokens is enabled' do
      before do
        stub_feature_flags(ajax_new_deploy_token: true)
      end

      it_behaves_like 'a deploy token in settings' do
        let(:entity_type) { 'group' }
        let(:page_path) { group_settings_repository_path(group) }
      end
    end

    context 'when ajax deploy tokens is disabled' do
      before do
        stub_feature_flags(ajax_new_deploy_token: false)
      end

      it_behaves_like 'a deploy token in settings' do
        let(:entity_type) { 'group' }
        let(:page_path) { group_settings_repository_path(group) }
      end
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
