# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Noteable::NotesChannel, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let_it_be(:read_api_token) { create(:personal_access_token, scopes: ['read_api'], user: user) }
  let_it_be(:read_user_token) { create(:personal_access_token, scopes: ['read_user'], user: user) }
  let_it_be(:read_api_and_read_user_token) do
    create(:personal_access_token, scopes: %w[read_user read_api], user: user)
  end

  let_it_be(:noteable) { create(:issue, project: project) }

  describe '#subscribed' do
    let(:subscribe_params) do
      {
        project_id: noteable.project_id,
        noteable_type: noteable.class.underscore,
        noteable_id: noteable.id
      }
    end

    before do
      stub_action_cable_connection current_user: user
    end

    it 'rejects the subscription when noteable params are missing' do
      subscribe(project_id: project.id)

      expect(subscription).to be_rejected
    end

    context 'on an issue' do
      it_behaves_like 'handle subscription based on user access'
    end

    context 'on a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it_behaves_like 'handle subscription based on user access'
    end
  end

  context 'with a personal access token' do
    let(:subscribe_params) do
      {
        project_id: noteable.project_id,
        noteable_type: noteable.class.underscore,
        noteable_id: noteable.id
      }
    end

    before do
      stub_action_cable_connection current_user: user, access_token: access_token
    end

    context 'with an api scoped personal access token' do
      let(:access_token) { read_api_token }

      it 'subscribes to the given graphql subscription' do
        subscribe(subscribe_params)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(noteable)
      end
    end

    context 'with a read_user personal access token' do
      let(:access_token) { read_user_token }

      it 'does not subscribe to the given graphql subscription' do
        subscribe(subscribe_params)

        expect(subscription).not_to be_confirmed
      end
    end

    context 'with a read_api and read_user personal access token' do
      let(:access_token) { read_api_and_read_user_token }

      it 'subscribes to the given graphql subscription' do
        subscribe(subscribe_params)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(noteable)
      end
    end
  end
end
