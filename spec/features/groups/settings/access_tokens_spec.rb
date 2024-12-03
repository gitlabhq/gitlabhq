# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group > Settings > Access tokens', :js, feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers
  include Features::AccessTokenHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:bot_user) { create(:user, :project_bot) }
  let_it_be(:group) { create(:group, owners: user) }
  let_it_be(:resource_settings_access_tokens_path) { group_settings_access_tokens_path(group) }

  before do
    sign_in(user)
  end

  def create_resource_access_token
    group.add_maintainer(bot_user)

    create(:personal_access_token, user: bot_user)
  end

  context 'when user is not a group owner' do
    before do
      group.add_maintainer(user)
    end

    it_behaves_like 'resource access tokens missing access rights'
  end

  describe 'token creation' do
    it_behaves_like 'resource access tokens creation', 'group'

    context 'when token creation is not allowed' do
      it_behaves_like 'resource access tokens creation disallowed', 'Group access token creation is disabled in this group.'
    end
  end

  describe 'active tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'active resource access tokens'
  end

  describe 'inactive tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'inactive resource access tokens', 'This group has no active access tokens.'
  end

  describe 'rotating tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'rotating token fails due to missing access rights', 'group' do
      let_it_be(:resource) { group }
    end

    context 'when user is owner of group' do
      before do
        group.add_owner(user)
      end

      it_behaves_like 'rotating token succeeds', 'group'
      it_behaves_like 'rotating already revoked token fails'
    end
  end
end
