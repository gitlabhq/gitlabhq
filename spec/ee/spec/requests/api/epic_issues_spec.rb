require 'spec_helper'

describe API::EpicIssues do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:epic) { create(:epic, group: group) }
  let(:issues) { create_list(:issue, 2, project: project) }
  let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issues[0], position: 1) }

  describe 'PUT /groups/:id/-/epics/:epic_iid/issues/:epic_issue_id' do
    let(:url) { "/groups/#{group.path}/-/epics/#{epic.iid}/issues/#{epic_issue1.id}?position=1" }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)
        put api(url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when an error occurs' do
        it 'returns 401 unauthorized error for non authenticated user' do
          put api(url)

          expect(response).to have_gitlab_http_status(401)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          put api(url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 403 forbidden error for a user who can not move the issue' do
          put api(url, user)

          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns 403 forbidden error for the link of another epic' do
          group.add_developer(user)
          another_epic = create(:epic, group: group)
          url = "/groups/#{group.path}/-/epics/#{another_epic.iid}/issues/#{epic_issue1.id}?position=1"

          put api(url, user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when the request is correct' do
        let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issues[1], position: 2) }

        before do
          group.add_developer(user)
          put api(url, user)
        end

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'updates the positions values' do
          expect(epic_issue1.reload.position).to eq(2)
          expect(epic_issue2.reload.position).to eq(1)
        end
      end
    end
  end
end
