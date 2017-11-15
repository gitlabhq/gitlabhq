require 'spec_helper'

describe Groups::EpicIssuesController do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, group: group) }
  let(:epic) { create(:epic, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:user)  { create(:user) }

  before do
    sign_in(user)
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    describe 'GET #index' do
      let!(:epic_issues) { create(:epic_issue, epic: epic, issue: issue) }

      before do
        group.add_developer(user)

        get :index, group_id: group, epic_id: epic.to_param
      end

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end

      it 'returns the correct json' do
        expected_result = [
          {
            'id' => issue.id,
            'title' => issue.title,
            'state' => issue.state,
            'reference' => "#{project.full_path}##{issue.iid}",
            'path' => "/#{project.full_path}/issues/#{issue.iid}",
            'destroy_relation_path' => "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issues.id}"
           }
        ]
        expect(JSON.parse(response.body)).to eq(expected_result)
      end
    end

    describe 'POST #create' do
      subject do
        reference = [issue.to_reference(full: true)]

        post :create, group_id: group, epic_id: epic.to_param, issue_references: reference
      end

      context 'when user has permissions to create requested association' do
        before do
          group.add_developer(user)
        end

        it 'returns correct response for the correct issue reference' do
          subject
          list_service_response = EpicIssues::ListService.new(epic, user).execute

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq('message' => nil, 'issues' => list_service_response.as_json)
        end

        it 'creates a new EpicIssue record' do
          expect { subject }.to change { EpicIssue.count }.from(0).to(1)
        end
      end

      context 'when user does not have permissions to create requested association' do
        it 'returns correct response for the correct issue reference' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not create a new EpicIssue record' do
          expect { subject }.not_to change { EpicIssue.count }.from(0)
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

      subject do
        delete :destroy, group_id: group, epic_id: epic.to_param, id: epic_issue.id
      end

      context 'when user has permissions to detele the link' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response.status).to eq(200)
        end

        it 'destroys the link' do
          expect { subject }.to change { EpicIssue.count }.from(1).to(0)
        end
      end

      context 'when user does not have permissions to delete the link' do
        it 'returns status 404' do
          subject

          expect(response.status).to eq(403)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end
      end

      context 'when the epic from the association does not equal epic from the path' do
        subject do
          delete :destroy, group_id: group, epic_id: another_epic.to_param, id: epic_issue.id
        end

        let(:another_epic) { create(:epic, group: group) }

        before do
          group.add_developer(user)
        end

        it 'returns status 404' do
          subject

          expect(response.status).to eq(404)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end
      end

      context 'when the epic_issue record does not exists' do
        it 'returns status 404' do
          delete :destroy, group_id: group, epic_id: epic.to_param, id: 9999

          expect(response.status).to eq(403)
        end
      end
    end
  end
end
