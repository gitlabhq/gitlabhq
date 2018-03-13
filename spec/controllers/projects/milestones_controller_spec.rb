require 'spec_helper'

describe Projects::MilestonesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:issue) { create(:issue, project: project, milestone: milestone) }
  let!(:label) { create(:label, project: project, title: 'Issue Label', issues: [issue]) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: milestone) }
  let(:milestone_path) { namespace_project_milestone_path }

  before do
    sign_in(user)
    project.add_master(user)
    controller.instance_variable_set(:@project, project)
  end

  it_behaves_like 'milestone tabs'

  describe "#show" do
    render_views

    def view_milestone(options = {})
      params = { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }
      get :show, params.merge(options)
    end

    it 'shows milestone page' do
      view_milestone

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'text/html'
    end

    it 'returns milestone json' do
      view_milestone format: :json

      expect(response).to have_http_status(404)
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe "#index" do
    context "as html" do
      before do
        get :index, namespace_id: project.namespace.id, project_id: project.id
      end

      it "queries only projects milestones" do
        milestones = assigns(:milestones)

        expect(milestones.count).to eq(1)
        expect(milestones.where(project_id: nil)).to be_empty
      end
    end

    context "as json" do
      let!(:group) { create(:group, :public) }
      let!(:group_milestone) { create(:milestone, group: group) }
      let!(:group_member) { create(:group_member, group: group, user: user) }

      before do
        project.update(namespace: group)
        get :index, namespace_id: project.namespace.id, project_id: project.id, format: :json
      end

      it "queries projects milestones and groups milestones" do
        milestones = assigns(:milestones)

        expect(milestones.count).to eq(2)
        expect(milestones.where(project_id: nil).first).to eq(group_milestone)
        expect(milestones.where(group_id: nil).first).to eq(milestone)
      end
    end
  end

  describe "#destroy" do
    it "removes milestone" do
      expect(issue.milestone_id).to eq(milestone.id)

      delete :destroy, namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid, format: :js
      expect(response).to be_success

      expect(Event.recent.first.action).to eq(Event::DESTROYED)

      expect { Milestone.find(milestone.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      issue.reload
      expect(issue.milestone_id).to eq(nil)

      merge_request.reload
      expect(merge_request.milestone_id).to eq(nil)

      # Check system note left for milestone removal
      last_note = project.issues.find(issue.id).notes[-1].note
      expect(last_note).to eq('removed milestone')
    end
  end

  describe '#promote' do
    context 'promotion succeeds' do
      before do
        group = create(:group)
        group.add_developer(user)
        milestone.project.update(namespace: group)
      end

      it 'shows group milestone' do
        post :promote, namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid

        expect(flash[:notice]).to eq("#{milestone.title} promoted to <a href=#{group_milestone_path(project.group, milestone.iid)}>group milestone.</a>")
        expect(response).to redirect_to(project_milestones_path(project))
      end
    end

    context 'promotion fails' do
      it 'shows project milestone' do
        post :promote, namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid

        expect(response).to redirect_to(project_milestone_path(project, milestone))
        expect(flash[:alert]).to eq('Promotion failed - Project does not belong to a group.')
      end
    end
  end
end
