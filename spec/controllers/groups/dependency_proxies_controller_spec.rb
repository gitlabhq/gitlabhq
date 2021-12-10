# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxiesController do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:dependency_proxy_group_setting) { create(:dependency_proxy_group_setting, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET #show' do
    subject { get :show, params: { group_id: group.to_param } }

    before do
      stub_config(dependency_proxy: { enabled: config_enabled })
    end

    context 'with global config enabled' do
      let(:config_enabled) { true }

      context 'with the setting enabled' do
        it 'returns 200 and renders the view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('groups/dependency_proxies/show')
        end
      end

      context 'with the setting disabled' do
        before do
          dependency_proxy_group_setting.update!(enabled: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with global config disabled' do
      let(:config_enabled) { false }

      it_behaves_like 'returning response status', :not_found
    end
  end
end
