# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ReleasesController, feature_category: :groups_and_projects do
  include AccessMatchersForController

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:private_project) { create(:project, :repository, :private) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:release_1) { create(:release, project: project, released_at: Time.zone.parse('2018-10-18')) }
  let_it_be(:release_2) { create(:release, project: project, released_at: Time.zone.parse('2019-10-19')) }

  let(:request_body) { '' }

  shared_examples 'common access controls' do
    it 'renders a 200' do
      perform_action(verb, action, params, request_body)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the project is private' do
      let(:project) { private_project }

      context 'when user is not logged in' do
        it 'renders a 404' do
          perform_action(verb, action, params, request_body)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is a developer' do
        before do
          sign_in(developer)
        end

        it 'still renders a 404' do
          perform_action(verb, action, params, request_body)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when activity_pub feature flag is disabled' do
      before do
        stub_feature_flags(activity_pub: false)
      end

      it 'renders a 404' do
        perform_action(verb, action, params, request_body)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when activity_pub_project feature flag is disabled' do
      before do
        stub_feature_flags(activity_pub_project: false)
      end

      it 'renders a 404' do
        perform_action(verb, action, params, request_body)

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
      perform_action(verb, action, params)
    end

    let(:verb) { :get }
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
      perform_action(verb, action, params)
    end

    let(:verb) { :get }
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

  describe 'POST #inbox' do
    before do
      allow(ActivityPub::Projects::ReleasesFollowService).to receive(:new) { follow_service }
      allow(ActivityPub::Projects::ReleasesUnfollowService).to receive(:new) { unfollow_service }
    end

    let(:verb) { :post }
    let(:action) { :inbox }
    let(:params) { { namespace_id: project.namespace, project_id: project } }

    let(:follow_service) do
      instance_double(ActivityPub::Projects::ReleasesFollowService, execute: true, errors: ['an error'])
    end

    let(:unfollow_service) do
      instance_double(ActivityPub::Projects::ReleasesUnfollowService, execute: true, errors: ['an error'])
    end

    context 'with a follow activity' do
      before do
        perform_action(verb, action, params, request_body)
      end

      let(:request_body) do
        {
          "@context": "https://www.w3.org/ns/activitystreams",
          id: "http://localhost:3001/6233e6c2-d285-4aa4-bd71-ddf1824d87f8",
          type: "Follow",
          actor: "http://localhost:3001/users/admin",
          object: "http://127.0.0.1:3000/flightjs/Flight/-/releases"
        }.to_json
      end

      it_behaves_like 'common access controls'

      context 'with successful subscription initialization' do
        it 'calls the subscription service' do
          expect(follow_service).to have_received :execute
        end

        it 'returns a successful response' do
          expect(json_response['success']).to be_truthy
        end

        it 'does not fill any error' do
          expect(json_response).not_to have_key 'errors'
        end
      end

      context 'with unsuccessful subscription initialization' do
        let(:follow_service) do
          instance_double(ActivityPub::Projects::ReleasesFollowService, execute: false, errors: ['an error'])
        end

        it 'calls the subscription service' do
          expect(follow_service).to have_received :execute
        end

        it 'returns a successful response' do
          expect(json_response['success']).to be_falsey
        end

        it 'fills an error' do
          expect(json_response['errors']).to include 'an error'
        end
      end
    end

    context 'with an unfollow activity' do
      before do
        perform_action(verb, action, params, request_body)
      end

      let(:unfollow_service) do
        instance_double(ActivityPub::Projects::ReleasesSubscriptionService, execute: true, errors: ['an error'])
      end

      let(:request_body) do
        {
          "@context": "https://www.w3.org/ns/activitystreams",
          id: "http://localhost:3001/users/admin#follows/8/undo",
          type: "Undo",
          actor: "http://localhost:3001/users/admin",
          object: {
            id: "http://localhost:3001/d4358269-71a9-4746-ac16-9a909f12ee5b",
            type: "Follow",
            actor: "http://localhost:3001/users/admin",
            object: "http://127.0.0.1:3000/flightjs/Flight/-/releases"
          }
        }.to_json
      end

      it_behaves_like 'common access controls'

      context 'with successful unfollow' do
        it 'calls the subscription service' do
          expect(unfollow_service).to have_received :execute
        end

        it 'returns a successful response' do
          expect(json_response['success']).to be_truthy
        end

        it 'does not fill any error' do
          expect(json_response).not_to have_key 'errors'
        end
      end

      context 'with unsuccessful unfollow' do
        let(:unfollow_service) do
          instance_double(ActivityPub::Projects::ReleasesUnfollowService, execute: false, errors: ['an error'])
        end

        it 'calls the subscription service' do
          expect(unfollow_service).to have_received :execute
        end

        it 'returns a successful response' do
          expect(json_response['success']).to be_falsey
        end

        it 'fills an error' do
          expect(json_response['errors']).to include 'an error'
        end
      end
    end

    context 'with an unknown activity' do
      before do
        perform_action(verb, action, params, request_body)
      end

      let(:request_body) do
        {
          "@context": "https://www.w3.org/ns/activitystreams",
          id: "http://localhost:3001/6233e6c2-d285-4aa4-bd71-ddf1824d87f8",
          type: "Like",
          actor: "http://localhost:3001/users/admin",
          object: "http://127.0.0.1:3000/flightjs/Flight/-/releases"
        }.to_json
      end

      it 'does not call the subscription service' do
        expect(follow_service).not_to have_received :execute
        expect(unfollow_service).not_to have_received :execute
      end

      it 'returns a successful response' do
        expect(json_response['success']).to be_truthy
      end

      it 'does not fill any error' do
        expect(json_response).not_to have_key 'errors'
      end
    end

    context 'with no activity' do
      it 'renders a 422' do
        perform_action(verb, action, params, request_body)
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end
end

def perform_action(verb, action, params, body = nil)
  send(verb, action, params: params, body: body)
end
