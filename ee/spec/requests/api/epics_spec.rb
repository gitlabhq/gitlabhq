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

  describe 'GET /groups/:id/epics' do
    let(:url) { "/groups/#{group.path}/epics" }

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

    context 'with multiple epics' do
      let(:user2) { create(:user) }
      let!(:epic) do
        create(:epic,
               group: group,
               created_at: 3.days.ago,
               updated_at: 2.days.ago)
      end
      let!(:epic2) do
        create(:epic,
               author: user2,
               group: group,
               title: 'foo',
               description: 'bar',
               created_at: 2.days.ago,
               updated_at: 3.days.ago)
      end
      let!(:label) { create(:group_label, title: 'a-test', group: group) }
      let!(:label_link) { create(:label_link, label: label, target: epic2) }

      before do
        stub_licensed_features(epics: true)
      end

      def expect_array_response(expected)
        items = json_response.map { |i| i['id'] }

        expect(items).to eq(expected)
      end

      it 'returns epics authored by the given author id' do
        get api(url, user), author_id: user2.id

        expect_array_response([epic2.id])
      end

      it 'returns epics matching given search string for title' do
        get api(url, user), search: epic2.title

        expect_array_response([epic2.id])
      end

      it 'returns epics matching given search string for description' do
        get api(url, user), search: epic2.description

        expect_array_response([epic2.id])
      end

      it 'sorts by created_at descending by default' do
        get api(url, user)

        expect_array_response([epic2.id, epic.id])
      end

      it 'sorts ascending when requested' do
        get api(url, user), sort: :asc

        expect_array_response([epic.id, epic2.id])
      end

      it 'sorts by updated_at descending when requested' do
        get api(url, user), order_by: :updated_at

        expect_array_response([epic.id, epic2.id])
      end

      it 'sorts by updated_at ascending when requested' do
        get api(url, user), order_by: :updated_at, sort: :asc

        expect_array_response([epic2.id, epic.id])
      end

      it 'returns an array of labeled epics' do
        get api(url, user), labels: label.title

        expect_array_response([epic2.id])
      end
    end
  end

  describe 'GET /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }

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

  describe 'POST /groups/:id/epics' do
    let(:url) { "/groups/#{group.path}/epics" }
    let(:params) { { title: 'new epic', description: 'epic description', labels: 'label1' } }

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
          expect(epic.labels.first.title).to eq('label1')
        end
      end
    end
  end

  describe 'PUT /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }
    let(:params) { { title: 'new title', description: 'new description', labels: 'label2' } }

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
          expect(result.labels.first.title).to eq('label2')
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }

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
