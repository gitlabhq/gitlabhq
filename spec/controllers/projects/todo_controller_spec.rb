require('spec_helper')

describe Projects::TodosController do
  let(:user)          { create(:user) }
  let(:project)       { create(:project) }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'Issues' do
    describe 'POST #create' do
      before do
        sign_in(user)
        project.team << [user, :developer]
      end

      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: issue.id,
                        issuable_type: "issue")
        end.to change { user.todos.count }.by(1)

        expect(response.status).to eq(200)
      end
    end

    describe 'POST #create when not authorized' do
      before do
        sign_in(user)
      end

      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: issue.id,
                        issuable_type: "issue")
        end.to change { user.todos.count }.by(0)

        expect(response.status).to eq(404)
      end
    end

    describe 'POST #create when not logged in' do
      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: issue.id,
                        issuable_type: "issue")
        end.to change { user.todos.count }.by(0)

        expect(response.status).to eq(302)
      end
    end
  end

  context 'Merge Requests' do
    describe 'POST #create' do
      before do
        sign_in(user)
        project.team << [user, :developer]
      end

      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: merge_request.id,
                        issuable_type: "merge_request")
        end.to change { user.todos.count }.by(1)

        expect(response.status).to eq(200)
      end
    end

    describe 'POST #create when not authorized' do
      before do
        sign_in(user)
      end

      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: merge_request.id,
                        issuable_type: "merge_request")
        end.to change { user.todos.count }.by(0)

        expect(response.status).to eq(404)
      end
    end

    describe 'POST #create when not logged in' do
      it 'should create todo for issue' do
        expect do
          post(:create, namespace_id: project.namespace.path,
                        project_id: project.path,
                        issuable_id: merge_request.id,
                        issuable_type: "merge_request")
        end.to change { user.todos.count }.by(0)

        expect(response.status).to eq(302)
      end
    end
  end
end
