# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TracingsController do
  let_it_be(:user) { create(:user) }

  describe 'GET show' do
    shared_examples 'user with read access' do |visibility_level|
      let(:project) { create(:project, visibility_level) }

      %w[developer maintainer].each do |role|
        context "with a #{visibility_level} project and #{role} role" do
          before do
            project.add_role(user, role)
          end

          it 'renders OK' do
            get :show, params: { namespace_id: project.namespace, project_id: project }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
          end
        end
      end
    end

    shared_examples 'user without read access' do |visibility_level|
      let(:project) { create(:project, visibility_level) }

      %w[guest reporter].each do |role|
        context "with a #{visibility_level} project and #{role} role" do
          before do
            project.add_role(user, role)
          end

          it 'returns 404' do
            get :show, params: { namespace_id: project.namespace, project_id: project }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    before do
      sign_in(user)
    end

    context 'with maintainer role' do
      it_behaves_like 'user with read access', :public
      it_behaves_like 'user with read access', :internal
      it_behaves_like 'user with read access', :private
    end

    context 'without maintainer role' do
      it_behaves_like 'user without read access', :public
      it_behaves_like 'user without read access', :internal
      it_behaves_like 'user without read access', :private
    end
  end
end
