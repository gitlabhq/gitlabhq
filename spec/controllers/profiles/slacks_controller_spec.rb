# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::SlacksController, feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    allow(subject).to receive(:current_user).and_return(user)
  end

  describe 'GET edit' do
    before do
      get :edit
    end

    it 'renders' do
      expect(response).to render_template :edit
    end

    it 'assigns projects' do
      expect(assigns[:projects]).to eq []
    end

    it 'assigns disabled_projects' do
      expect(assigns[:disabled_projects]).to eq []
    end
  end

  describe 'GET slack_link' do
    let_it_be(:project) { create(:project) }

    context 'when user is not a maintainer of the project' do
      before do
        project.add_developer(user)
      end

      it 'renders 404' do
        get :slack_link, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.body).to be_blank
      end
    end

    context 'when user is a maintainer of the project' do
      before do
        project.add_maintainer(user)
      end

      it 'renders slack link' do
        allow(controller).to receive(:add_to_slack_link).and_return('mock_redirect_link')

        get :slack_link, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'add_to_slack_link' => 'mock_redirect_link' })
      end
    end
  end
end
