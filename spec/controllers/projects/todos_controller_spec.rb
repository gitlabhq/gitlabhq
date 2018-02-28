require('spec_helper')

describe Projects::TodosController do
  let(:user)          { create(:user) }
  let(:project)       { create(:project) }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'Issues' do
    describe 'POST create' do
      def go
        post :create,
          namespace_id: project.namespace,
          project_id: project,
          issuable_id: issue.id,
          issuable_type: 'issue',
          format: 'html'
      end

      context 'when authorized' do
        before do
          sign_in(user)
          project.add_developer(user)
        end

        it 'creates todo for issue' do
          expect do
            go
          end.to change { user.todos.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'returns todo path and pending count' do
          go

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq 1
          expect(json_response['delete_path']).to match(%r{/dashboard/todos/\d{1}})
        end
      end

      context 'when not authorized for project' do
        it 'does not create todo for issue that user has no access to' do
          sign_in(user)
          expect do
            go
          end.to change { user.todos.count }.by(0)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'does not create todo for issue when user not logged in' do
          expect do
            go
          end.to change { user.todos.count }.by(0)

          expect(response).to have_gitlab_http_status(302)
        end
      end

      context 'when not authorized for issue' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          sign_in(user)
        end

        it "doesn't create todo" do
          expect { go }.not_to change { user.todos.count }
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  context 'Merge Requests' do
    describe 'POST create' do
      def go
        post :create,
          namespace_id: project.namespace,
          project_id: project,
          issuable_id: merge_request.id,
          issuable_type: 'merge_request',
          format: 'html'
      end

      context 'when authorized' do
        before do
          sign_in(user)
          project.add_developer(user)
        end

        it 'creates todo for merge request' do
          expect do
            go
          end.to change { user.todos.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'returns todo path and pending count' do
          go

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq 1
          expect(json_response['delete_path']).to match(%r{/dashboard/todos/\d{1}})
        end
      end

      context 'when not authorized for project' do
        it 'does not create todo for merge request user has no access to' do
          sign_in(user)
          expect do
            go
          end.to change { user.todos.count }.by(0)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'does not create todo for merge request user has no access to' do
          expect do
            go
          end.to change { user.todos.count }.by(0)

          expect(response).to have_gitlab_http_status(302)
        end
      end

      context 'when not authorized for merge_request' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
          sign_in(user)
        end

        it "doesn't create todo" do
          expect { go }.not_to change { user.todos.count }
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
