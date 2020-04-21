# frozen_string_literal: true

require 'spec_helper'

describe 'Group Repository settings' do
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
end
