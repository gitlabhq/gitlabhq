# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::TodosController do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:design)        { create(:design, project: project, issue: issue) }
  let(:parent)        { project }

  shared_examples 'issuable todo actions' do
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

      it_behaves_like 'issuable todo actions'
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

      it_behaves_like 'issuable todo actions'
    end
  end

  context 'Designs' do
    include DesignManagementTestHelpers

    before do
      enable_design_management
    end

    describe 'POST create' do
      def post_create
        post :create,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            issue_id: issue.id,
            issuable_id: design.id,
            issuable_type: 'design'
          },
          format: 'html'
      end

      it_behaves_like 'todos actions'
    end
  end
end
