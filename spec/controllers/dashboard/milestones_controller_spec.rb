require 'spec_helper'

describe Dashboard::MilestonesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:project_milestone) { create(:milestone, project: project) }
  let(:milestone) do
    DashboardMilestone.build(
      [project],
      project_milestone.title
    )
  end
  let(:issue) { create(:issue, project: project, milestone: project_milestone) }
  let!(:label) { create(:label, project: project, title: 'Issue Label', issues: [issue]) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: project_milestone) }
  let(:milestone_path) { dashboard_milestone_path(milestone.safe_title, title: milestone.title) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  it_behaves_like 'milestone tabs'

  describe "#show" do
    render_views

    def view_milestone
      get :show, id: milestone.safe_title, title: milestone.title
    end

    it 'shows milestone page' do
      view_milestone

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
