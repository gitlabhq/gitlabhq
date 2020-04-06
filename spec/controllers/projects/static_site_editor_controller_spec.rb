# frozen_string_literal: true

require 'spec_helper'

describe Projects::StaticSiteEditorController do
  let(:project) { create(:project, :public, :repository) }

  describe 'GET show' do
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/README.md'
      }
    end

    context 'User roles' do
      context 'anonymous' do
        before do
          get :show, params: default_params
        end

        it 'redirects to sign in and returns' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      %w[guest developer maintainer].each do |role|
        context "as #{role}" do
          let(:user) { create(:user) }

          before do
            project.add_role(user, role)
            sign_in(user)
            get :show, params: default_params
          end

          it 'renders the edit page' do
            expect(response).to render_template(:show)
          end
        end
      end
    end
  end
end
