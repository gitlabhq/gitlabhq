require 'spec_helper'

describe API::Epics do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:epic) { create(:epic, group: group) }
  let(:params) { nil }

  shared_examples 'error requests' do
    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)

        get api(url, user), params

        expect(response).to have_gitlab_http_status(403)
      end

      context 'when epics feature is enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'returns 401 unauthorized error for non authenticated user' do
          get api(url), params

          expect(response).to have_gitlab_http_status(401)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          get api(url, user), params

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'GET /groups/:id/-/epics' do
    let(:url) { "/groups/#{group.path}/-/epics" }

    it_behaves_like 'error requests'

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it 'returns 200 status' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'matches the response schema' do
        expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
      end
    end
  end

  describe 'GET /groups/:id/-/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/-/epics/#{epic.iid}" }

    it_behaves_like 'error requests'

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it 'returns 200 status' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'matches the response schema' do
        expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
      end
    end
  end

  describe 'POST /groups/:id/-/epics' do
    let(:url) { "/groups/#{group.path}/-/epics" }
    let(:params) { { title: 'new epic', description: 'epic description' } }

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when required parameter is missing' do
        it 'returns 400' do
          group.add_developer(user)

          post api(url, user), description: 'epic description'

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'when the request is correct' do
        before do
          group.add_developer(user)

          post api(url, user), params
        end

        it 'returns 201 status' do
          expect(response).to have_gitlab_http_status(201)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
        end

        it 'creates a new epic' do
          epic = Epic.last

          expect(epic.title).to eq('new epic')
          expect(epic.description).to eq('epic description')
        end
      end
    end
  end

  describe 'PUT /groups/:id/-/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/-/epics/#{epic.iid}" }
    let(:params) { { title: 'new title', description: 'new description' } }

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user does not have permissions to create an epic' do
        it 'returns 403 forbidden error' do
          put api(url, user), params

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when no param sent' do
        it 'returns 400' do
          group.add_developer(user)

          put api(url, user)

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'when the request is correct' do
        before do
          group.add_developer(user)

          put api(url, user), params
        end

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
        end

        it 'updates the epic' do
          result = epic.reload

          expect(result.title).to eq('new title')
          expect(result.description).to eq('new description')
        end
      end
    end
  end

  describe 'DELETE /groups/:id/-/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/-/epics/#{epic.iid}" }

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user does not have permissions to destroy an epic' do
        it 'returns 403 forbidden error' do
          group.add_developer(user)

          delete api(url, user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when the request is correct' do
        before do
          group.add_owner(user)
        end

        it 'returns 204 status' do
          delete api(url, user)

          expect(response).to have_gitlab_http_status(204)
        end

        it 'removes an epic' do
          epic

          expect { delete api(url, user) }.to change { Epic.count }.from(1).to(0)
        end
      end
    end
  end
end
