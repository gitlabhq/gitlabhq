# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TerraformController do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
        subject
      end

      it 'renders content' do
        expect(response).to be_successful
      end
    end

    context 'when user is unauthorized' do
      let(:user) { create(:user) }

      before do
        project.add_guest(user)
        sign_in(user)
        subject
      end

      it 'shows 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when no user is present' do
      before do
        subject
      end

      it 'shows 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
