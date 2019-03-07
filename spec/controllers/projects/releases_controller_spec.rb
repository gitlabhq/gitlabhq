# frozen_string_literal: true

require 'spec_helper'

describe Projects::ReleasesController do
  let!(:project) { create(:project, :repository, :public) }
  let!(:user)    { create(:user) }

  describe 'GET #index' do
    it 'renders a 200' do
      get_index

      expect(response.status).to eq(200)
    end

    context 'when the project is private' do
      let!(:project) { create(:project, :repository, :private) }

      it 'renders a 302' do
        get_index

        expect(response.status).to eq(302)
      end

      it 'renders a 200 for a logged in developer' do
        project.add_developer(user)
        sign_in(user)

        get_index

        expect(response.status).to eq(200)
      end

      it 'renders a 404 when logged in but not in the project' do
        sign_in(user)

        get_index

        expect(response.status).to eq(404)
      end
    end
  end

  private

  def get_index
    get :index, params: { namespace_id: project.namespace, project_id: project }
  end
end
