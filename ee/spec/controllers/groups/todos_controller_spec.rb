require('spec_helper')

describe Groups::TodosController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:epic)  { create(:epic, group: group) }

  describe 'POST create' do
    subject { post :create, group_id: group, issuable_id: epic.id, issuable_type: 'epic', format: :json }

    context 'when authorized' do
      before do
        sign_in(user)
      end

      it 'creates todo for epic' do
        expect { subject }.to change { user.todos.count }.by(1)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns todo path and pending count' do
        subject

        expect(json_response['count']).to eq 1
        expect(json_response['delete_path']).to match(%r{/dashboard/todos/\d{1}})
      end
    end

    context 'when not authorized for project' do
      it 'does not create todo for epic that user has no access to' do
        group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        sign_in(user)

        expect { subject }.not_to change { user.todos.count }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not create todo for epic when user not logged in' do
        expect { subject }.not_to change { user.todos.count }

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
