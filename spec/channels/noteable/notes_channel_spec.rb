# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Noteable::NotesChannel, :with_current_organization, feature_category: :team_planning do
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
      stub_action_cable_connection current_user: user, current_organization: current_organization
    end

    it 'rejects the subscription when noteable params are missing' do
      subscribe(project_id: project.id)

      expect(subscription).to be_rejected
    end

    it 'passes organization_id to NotesFinder' do
      expect(NotesFinder).to receive(:new).with(
        user,
        hash_including(organization_id: current_organization.id)
      ).and_call_original

      subscribe(subscribe_params)
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
      stub_action_cable_connection current_user: user, access_token: access_token,
        current_organization: current_organization
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

    context 'with a granular personal access token' do
      context 'when scoped to the noteable project with the required permission' do
        let(:access_token) do
          create(:granular_pat, user: user, boundary: Authz::Boundary.for(project), permissions: :read_work_item)
        end

        it 'subscribes to the given noteable' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription).to have_stream_for(noteable)
        end
      end

      context 'without the required permission' do
        let(:access_token) { create(:granular_pat, user: user) }

        it 'rejects the subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end

      context 'when scoped to a different project' do
        let_it_be(:other_project) { create(:project, developers: user) }
        let(:access_token) do
          create(:granular_pat, user: user, boundary: Authz::Boundary.for(other_project), permissions: :read_work_item)
        end

        it 'rejects the subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end
    end

    context 'with a parent-less noteable' do
      let_it_be(:personal_snippet) { create(:personal_snippet, author: user, organization: current_organization) }

      let(:subscribe_params) do
        {
          noteable_type: 'personal_snippet',
          noteable_id: personal_snippet.id
        }
      end

      context 'with a granular personal access token' do
        let(:access_token) do
          create(:granular_pat, user: user, boundary: Authz::Boundary.for(project), permissions: :read_work_item)
        end

        it 'rejects the subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end

      context 'with a legacy personal access token' do
        let(:access_token) { read_api_token }

        it 'subscribes to the given noteable' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription).to have_stream_for(personal_snippet)
        end
      end
    end

    context 'when the namespace enforces granular tokens' do
      let_it_be_with_reload(:enforced_group) { create(:group, organization: current_organization) }
      let_it_be(:enforced_project) { create(:project, :private, group: enforced_group, developers: user) }
      let_it_be(:noteable) { create(:issue, project: enforced_project) }

      before do
        enforced_group.namespace_settings.update!(
          enforce_granular_tokens: true,
          granular_tokens_enforced_after: Date.current
        )
      end

      context 'with a legacy personal access token' do
        let(:access_token) { read_api_token }

        it 'rejects the subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end

      context 'with a granular personal access token carrying the permission' do
        let(:access_token) do
          create(:granular_pat, user: user, boundary: Authz::Boundary.for(enforced_project),
            permissions: :read_work_item)
        end

        it 'subscribes to the given noteable' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription).to have_stream_for(noteable)
        end
      end
    end
  end
end
