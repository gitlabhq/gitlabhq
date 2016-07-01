require('spec_helper')

describe Projects::TodosController do
  let(:user)          { create(:user) }
  let(:project)       { create(:project) }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'Issues' do
    describe 'POST create' do
      context 'when authorized' do
        before do
          sign_in(user)
          project.team << [user, :developer]
        end

        it 'should create todo for issue' do
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: issue.id,
                          issuable_type: 'issue')
          end.to change { user.todos.count }.by(1)

          expect(response).to have_http_status(200)
        end
      end

      context 'when not authorized' do
        it 'should not create todo for issue that user has no access to' do
          sign_in(user)
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: issue.id,
                          issuable_type: 'issue')
          end.to change { user.todos.count }.by(0)

          expect(response).to have_http_status(404)
        end

        it 'should not create todo for issue when user not logged in' do
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: issue.id,
                          issuable_type: 'issue')
          end.to change { user.todos.count }.by(0)

          expect(response).to have_http_status(302)
        end
      end
    end
  end

  context 'Merge Requests' do
    describe 'POST create' do
      context 'when authorized' do
        before do
          sign_in(user)
          project.team << [user, :developer]
        end

        it 'should create todo for merge request' do
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: merge_request.id,
                          issuable_type: 'merge_request')
          end.to change { user.todos.count }.by(1)

          expect(response).to have_http_status(200)
        end
      end

      context 'when not authorized' do
        it 'should not create todo for merge request user has no access to' do
          sign_in(user)
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: merge_request.id,
                          issuable_type: 'merge_request')
          end.to change { user.todos.count }.by(0)

          expect(response).to have_http_status(404)
        end

        it 'should not create todo for merge request user has no access to' do
          expect do
            post(:create, namespace_id: project.namespace.path,
                          project_id: project.path,
                          issuable_id: merge_request.id,
                          issuable_type: 'merge_request')
          end.to change { user.todos.count }.by(0)

          expect(response).to have_http_status(302)
        end
      end
    end
  end
end
