# frozen_string_literal: true

require 'spec_helper'

describe Projects::ReleasesController do
  let!(:project)         { create(:project, :repository, :public) }
  let!(:private_project) { create(:project, :repository, :private) }
  let!(:user)            { create(:user) }
  let!(:release_1)       { create(:release, project: project, released_at: Time.zone.parse('2018-10-18')) }
  let!(:release_2)       { create(:release, project: project, released_at: Time.zone.parse('2019-10-19')) }

  shared_examples 'common access controls' do
    it 'renders a 200' do
      get_index

      expect(response.status).to eq(200)
    end

    context 'when the project is private' do
      let(:project) { private_project }

      before do
        sign_in(user)
      end

      it 'renders a 200 for a logged in developer' do
        project.add_developer(user)

        get_index

        expect(response.status).to eq(200)
      end

      it 'renders a 404 when logged in but not in the project' do
        get_index

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'GET #index' do
    before do
      get_index
    end

    context 'as html' do
      let(:format) { :html }

      it 'returns a text/html content_type' do
        expect(response.content_type).to eq 'text/html'
      end

      it_behaves_like 'common access controls'

      context 'when the project is private and the user is not logged in' do
        let(:project) { private_project }

        it 'returns a redirect' do
          expect(response).to have_gitlab_http_status(:redirect)
        end
      end
    end

    context 'as json' do
      let(:format) { :json }

      it 'returns an application/json content_type' do
        expect(response.content_type).to eq 'application/json'
      end

      it "returns the project's releases as JSON, ordered by released_at" do
        expect(response.body).to eq([release_2, release_1].to_json)
      end

      it_behaves_like 'common access controls'

      context 'when the project is private and the user is not logged in' do
        let(:project) { private_project }

        it 'returns a redirect' do
          expect(response).to have_gitlab_http_status(:redirect)
        end
      end
    end
  end

  private

  def get_index
    get :index, params: { namespace_id: project.namespace, project_id: project, format: format }
  end
end
