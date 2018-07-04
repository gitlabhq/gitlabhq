require 'spec_helper'

describe API::Todos do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  subject { post api("/groups/#{group.id}/epics/#{epic.iid}/todo", user) }

  describe 'POST :id/epics/:epic_iid/todo' do
    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'creates a todo on an epic' do
        expect { subject }.to change { Todo.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response['project']).to be_nil
        expect(json_response['group']).to be_a(Hash)
        expect(json_response['author']).to be_a(Hash)
        expect(json_response['target_type']).to eq('Epic')
        expect(json_response['target']).to be_a(Hash)
        expect(json_response['target_url']).to be_present
        expect(json_response['body']).to be_present
        expect(json_response['state']).to eq('pending')
        expect(json_response['action_name']).to eq('marked')
        expect(json_response['created_at']).to be_present
      end

      it 'returns 304 there already exist a todo on that epic' do
        create(:todo, project: nil, group: group, user: user, target: epic)

        subject

        expect(response.status).to eq(304)
      end

      it 'returns 404 if the epic is not found' do
        post api("/groups/#{group.id}/epics/9999/todo", user)

        expect(response.status).to eq(403)
      end

      it 'returns an error if the epic is not accessible' do
        group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
