require 'spec_helper'

describe Dashboard::MilestonesController do
  let(:project) { create(:project) }
  let(:group) { create(:group) }
  let(:public_group) { create(:group, :public) }
  let(:user) { create(:user) }
  let(:project_milestone) { create(:milestone, project: project) }
  let(:group_milestone) { create(:milestone, group: group) }
  let!(:public_milestone) { create(:milestone, group: public_group) }
  let(:milestone) do
    DashboardMilestone.build(
      [project],
      project_milestone.title
    )
  end
  let(:issue) { create(:issue, project: project, milestone: project_milestone) }
  let(:group_issue) { create(:issue, milestone: group_milestone) }

  let!(:label) { create(:label, project: project, title: 'Issue Label', issues: [issue]) }
  let!(:group_label) { create(:group_label, group: group, title: 'Group Issue Label', issues: [group_issue]) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: project_milestone) }
  let(:milestone_path) { dashboard_milestone_path(milestone.safe_title, title: milestone.title) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_developer(user)
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

  describe "#index" do
    it 'returns group and project milestones to which the user belongs' do
      get :index, format: :json

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |i| i["first_milestone"]["id"] }).to match_array([group_milestone.id, project_milestone.id])
      expect(json_response.map { |i| i["group_name"] }.compact).to match_array(group.name)
    end
  end
end
