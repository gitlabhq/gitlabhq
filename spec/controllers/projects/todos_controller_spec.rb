# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::TodosController do
  let(:user)          { create(:user) }
  let(:project)       { create(:project) }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:parent)        { project }

  shared_examples 'project todos actions' do
    it_behaves_like 'todos actions'

    context 'when not authorized for resource' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        sign_in(user)
      end

      it "doesn't create todo" do
        expect { post_create }.not_to change { user.todos.count }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'Issues' do
    describe 'POST create' do
      def post_create
        post :create,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            issuable_id: issue.id,
            issuable_type: 'issue'
          },
          format: 'html'
      end

      it_behaves_like 'project todos actions'
    end
  end

  context 'Merge Requests' do
    describe 'POST create' do
      def post_create
        post :create,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            issuable_id: merge_request.id,
            issuable_type: 'merge_request'
          },
          format: 'html'
      end

      it_behaves_like 'project todos actions'
    end
  end
end
