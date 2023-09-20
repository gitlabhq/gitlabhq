# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ReleasesController, feature_category: :groups_and_projects do
  include AccessMatchersForController

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:private_project) { create(:project, :repository, :private) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:release_1) { create(:release, project: project, released_at: Time.zone.parse('2018-10-18')) }
  let_it_be(:release_2) { create(:release, project: project, released_at: Time.zone.parse('2019-10-19')) }

  before_all do
    project.add_developer(developer)
  end

  shared_examples 'common access controls' do
    it 'renders a 200' do
      get(action, params: params)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the project is private' do
      let(:project) { private_project }

      context 'when user is not logged in' do
        it 'renders a 404' do
          get(action, params: params)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is a developer' do
        before do
          sign_in(developer)
        end

        it 'still renders a 404' do
          get(action, params: params)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when activity_pub feature flag is disabled' do
      before do
        stub_feature_flags(activity_pub: false)
      end

      it 'renders a 404' do
        get(action, params: params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when activity_pub_project feature flag is disabled' do
      before do
        stub_feature_flags(activity_pub_project: false)
      end

      it 'renders a 404' do
        get(action, params: params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples_for 'ActivityPub response' do
    it 'returns an application/activity+json content_type' do
      expect(response.media_type).to eq 'application/activity+json'
    end

    it 'is formated as an ActivityStream document' do
      expect(json_response['@context']).to eq 'https://www.w3.org/ns/activitystreams'
    end
  end

  describe 'GET #index' do
    before do
      get(action, params: params)
    end

    let(:action) { :index }
    let(:params) { { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'common access controls'
    it_behaves_like 'ActivityPub response'

    it "returns the project's releases actor profile data" do
      expect(json_response['id']).to include project_releases_path(project)
    end
  end

  describe 'GET #outbox' do
    before do
      get(action, params: params)
    end

    let(:action) { :outbox }
    let(:params) { { namespace_id: project.namespace, project_id: project, page: page } }

    context 'with no page parameter' do
      let(:page) { nil }

      it_behaves_like 'common access controls'
      it_behaves_like 'ActivityPub response'

      it "returns the project's releases collection index" do
        expect(json_response['id']).to include outbox_project_releases_path(project)
        expect(json_response['totalItems']).to eq 2
      end
    end

    context 'with a page parameter' do
      let(:page) { 1 }

      it_behaves_like 'common access controls'
      it_behaves_like 'ActivityPub response'

      it "returns the project's releases list" do
        expect(json_response['id']).to include outbox_project_releases_path(project, page: 1)

        names = json_response['orderedItems'].map { |release| release['object']['name'] }
        expect(names).to match_array([release_2.name, release_1.name])
      end
    end
  end
end
