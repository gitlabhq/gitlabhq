# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UsageQuotasController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe 'GET #index' do
    render_views

    subject { get(:index, params: { namespace_id: project.namespace, project_id: project }) }

    before do
      sign_in(user)
    end

    context 'when user does not have read_usage_quotas permission' do
      before do
        project.add_developer(user)
      end

      it 'renders not_found' do
        subject

        expect(response).to render_template('errors/not_found')
        expect(response).not_to render_template('shared/search_settings')
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has read_usage_quotas permission' do
      before do
        project.add_maintainer(user)
      end

      it 'renders index with 200 status code' do
        subject

        expect(response).to render_template('index')
        expect(response).not_to render_template('shared/search_settings')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
