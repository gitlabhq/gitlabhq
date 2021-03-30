# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MilestonesController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:issue) { create(:issue, project: project, milestone: milestone) }
  let!(:label) { create(:label, project: project, title: 'Issue Label', issues: [issue]) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: milestone) }
  let(:milestone_path) { namespace_project_milestone_path }

  before do
    sign_in(user)
    project.add_maintainer(user)
    controller.instance_variable_set(:@project, project)
  end

  it_behaves_like 'milestone tabs' do
    let(:request_params) { { namespace_id: project.namespace, project_id: project, id: milestone.iid } }
  end

  describe "#show" do
    render_views

    def view_milestone(options = {})
      params = { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }
      get :show, params: params.merge(options)
    end

    it 'shows milestone page' do
      view_milestone

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq 'text/html'
    end

    it 'returns milestone json' do
      view_milestone format: :json

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe "#index" do
    context "as html" do
      def render_index(project:, page:, search_title: '')
        get :index, params: {
                      namespace_id: project.namespace.id,
                      project_id: project.id,
                      search_title: search_title,
                      page: page
                    }
      end

      it "queries only projects milestones" do
        render_index project: project, page: 1

        milestones = assigns(:milestones)

        expect(milestones.count).to eq(1)
        expect(milestones.where(project_id: nil)).to be_empty
      end

      it 'searches milestones by title when search_title is given' do
        milestone1 = create(:milestone, title: 'Project milestone title', project: project)

        render_index project: project, page: 1, search_title: 'Project mile'

        milestones = assigns(:milestones)
        expect(milestones).to eq([milestone1])
      end

      it 'renders paginated milestones without missing or duplicates' do
        allow(Milestone).to receive(:default_per_page).and_return(2)
        create_list(:milestone, 5, project: project)

        render_index project: project, page: 1
        page_1_milestones = assigns(:milestones)
        expect(page_1_milestones.size).to eq(2)

        render_index project: project, page: 2
        page_2_milestones = assigns(:milestones)
        expect(page_2_milestones.size).to eq(2)

        render_index project: project, page: 3
        page_3_milestones = assigns(:milestones)
        expect(page_3_milestones.size).to eq(2)

        rendered_milestone_ids =
          page_1_milestones.pluck(:id) +
          page_2_milestones.pluck(:id) +
          page_3_milestones.pluck(:id)

        expect(rendered_milestone_ids)
          .to match_array(project.milestones.pluck(:id))
      end
    end

    context "as json" do
      let!(:group) { create(:group, :public) }
      let!(:group_milestone) { create(:milestone, group: group) }

      context 'with a single group ancestor' do
        before do
          project.update!(namespace: group)
          get :index, params: { namespace_id: project.namespace.id, project_id: project.id }, format: :json
        end

        it "queries projects milestones and groups milestones" do
          milestones = assigns(:milestones)

          expect(milestones.count).to eq(2)
          expect(milestones).to match_array([milestone, group_milestone])
        end
      end

      context 'with nested groups' do
        let!(:subgroup) { create(:group, :public, parent: group) }
        let!(:subgroup_milestone) { create(:milestone, group: subgroup) }

        before do
          project.update!(namespace: subgroup)
          get :index, params: { namespace_id: project.namespace.id, project_id: project.id }, format: :json
        end

        it "queries projects milestones and all ancestors milestones" do
          milestones = assigns(:milestones)

          expect(milestones.count).to eq(3)
          expect(milestones).to match_array([milestone, group_milestone, subgroup_milestone])
        end
      end
    end
  end

  describe "#destroy" do
    it "removes milestone" do
      expect(issue.milestone_id).to eq(milestone.id)

      delete :destroy, params: { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }, format: :js
      expect(response).to be_successful

      expect(Event.recent.first).to be_destroyed_action

      expect { Milestone.find(milestone.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      issue.reload
      expect(issue.milestone_id).to eq(nil)

      merge_request.reload
      expect(merge_request.milestone_id).to eq(nil)
    end
  end

  describe '#promote' do
    let(:group) { create(:group) }

    before do
      project.update!(namespace: group)
    end

    context 'when user does not have permission to promote milestone' do
      before do
        group.add_guest(user)
      end

      it 'renders 404' do
        post :promote, params: { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe '#labels' do
      render_views

      context 'as json' do
        let!(:guest) { create(:user, username: 'guest1') }
        let!(:group) { create(:group, :public) }
        let!(:project) { create(:project, :public, group: group) }
        let!(:label) { create(:label, title: 'test_label_on_private_issue', project: project) }
        let!(:confidential_issue) { create(:labeled_issue, confidential: true, project: project, milestone: milestone, labels: [label]) }

        it 'does not render labels of private issues if user has no access' do
          sign_in(guest)

          get :labels, params: { namespace_id: group.id, project_id: project.id, id: milestone.iid }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq 'application/json'

          expect(json_response['html']).not_to include(label.title)
        end

        it 'does render labels of private issues if user has access' do
          sign_in(user)

          get :labels, params: { namespace_id: group.id, project_id: project.id, id: milestone.iid }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq 'application/json'

          expect(json_response['html']).to include(label.title)
        end
      end
    end

    context 'promotion succeeds' do
      before do
        group.add_developer(user)
      end

      it 'shows group milestone' do
        post :promote, params: { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }

        expect(flash[:notice]).to eq("#{milestone.title} promoted to <a href=\"#{group_milestone_path(project.group, milestone.iid)}\"><u>group milestone</u></a>.")
        expect(response).to redirect_to(project_milestones_path(project))
      end

      it 'renders milestone name without parsing it as HTML' do
        milestone.update!(name: 'CCC&lt;img src=x onerror=alert(document.domain)&gt;')

        post :promote, params: { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }

        expect(flash[:notice]).to eq("CCC promoted to <a href=\"#{group_milestone_path(project.group, milestone.iid)}\"><u>group milestone</u></a>.")
      end
    end

    context 'when user cannot admin group milestones' do
      before do
        project.add_developer(user)
      end

      it 'renders 404' do
        project.update!(namespace: user.namespace)

        post :promote, params: { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#participants' do
    render_views

    context "when guest user" do
      let(:issue_assignee) { create(:user) }
      let(:guest_user) { create(:user) }

      before do
        project.add_guest(guest_user)
        sign_in(guest_user)
        issue.update!(assignee_ids: issue_assignee.id)
      end

      context "when issue is not confidential" do
        it 'shows milestone participants' do
          params = { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid, format: :json }
          get :participants, params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq 'application/json'
          expect(json_response['html']).to include(issue_assignee.name)
        end
      end

      context "when issue is confidential" do
        before do
          issue.update!(confidential: true)
        end

        it 'shows no milestone participants' do
          params = { namespace_id: project.namespace.id, project_id: project.id, id: milestone.iid, format: :json }
          get :participants, params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq 'application/json'
          expect(json_response['html']).not_to include(issue_assignee.name)
        end
      end
    end
  end
end
