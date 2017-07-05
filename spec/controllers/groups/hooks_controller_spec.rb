require 'spec_helper'

describe Groups::HooksController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with group_webhooks enabled' do
    before do
      stub_licensed_features(group_webhooks: true)
    end

    describe 'GET #index' do
      it 'is successfull' do
        get :index, group_id: group.to_param

        expect(response).to have_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'sets all parameters' do
        hook_params = {
          job_events: true,
          confidential_issues_events: true,
          enable_ssl_verification: true,
          issues_events: true,
          merge_requests_events: true,
          note_events: true,
          pipeline_events: true,
          push_events: true,
          tag_push_events: true,
          token: "TEST TOKEN",
          url: "http://example.com",
          wiki_page_events: true
        }

        post :create, group_id: group.to_param, hook: hook_params

        expect(response).to have_http_status(302)
        expect(group.hooks.size).to eq(1)
        expect(group.hooks.first).to have_attributes(hook_params)
      end
    end
  end

  context 'with group_webhooks disabled' do
    before do
      stub_licensed_features(group_webhooks: false)
    end

    describe 'GET #index' do
      it 'renders a 404' do
        get :index, group_id: group.to_param

        expect(response).to have_http_status(404)
      end
    end
  end
end
