require 'spec_helper'

describe Projects::CycleAnalyticsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'cycle analytics not set up flag' do
    context 'with no data' do
      it 'is true' do
        get(:show,
            namespace_id: project.namespace,
            project_id: project)

        expect(response).to be_success
        expect(assigns(:cycle_analytics_no_data)).to eq(true)
      end
    end

    context 'with data' do
      before do
        issue = create(:issue, project: project, created_at: 4.days.ago)
        milestone = create(:milestone, project: project, created_at: 5.days.ago)
        issue.update(milestone: milestone)

        create_merge_request_closing_issue(user, project, issue)
      end

      it 'is false' do
        get(:show,
            namespace_id: project.namespace,
            project_id: project)

        expect(response).to be_success
        expect(assigns(:cycle_analytics_no_data)).to eq(false)
      end
    end
  end
end
