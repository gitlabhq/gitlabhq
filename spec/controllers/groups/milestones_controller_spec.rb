require 'spec_helper'

describe Groups::MilestonesController do
  let(:group) { create(:group) }
  let!(:project) { create(:project, group: group) }
  let!(:project2) { create(:project, group: group) }
  let(:user)    { create(:user) }
  let(:title) { '肯定不是中文的问题' }
  let(:milestone) do
    project_milestone = create(:milestone, project: project)

    GroupMilestone.build(
      group,
      [project],
      project_milestone.title
    )
  end
  let(:milestone_path) { group_milestone_path(group, milestone.safe_title, title: milestone.title) }

  let(:milestone_params) do
    {
      title: title,
      start_date: Date.today,
      due_date: 1.month.from_now.to_date
    }
  end

  before do
    sign_in(user)
    group.add_owner(user)
    project.add_master(user)
  end

  describe '#index' do
    it 'shows group milestones page' do
      get :index, group_id: group.to_param

      expect(response).to have_gitlab_http_status(200)
    end

    context 'as JSON' do
      let!(:milestone) { create(:milestone, group: group, title: 'group milestone') }
      let!(:legacy_milestone1) { create(:milestone, project: project, title: 'legacy') }
      let!(:legacy_milestone2) { create(:milestone, project: project2, title: 'legacy') }

      it 'lists legacy group milestones and group milestones' do
        get :index, group_id: group.to_param, format: :json

        milestones = JSON.parse(response.body)

        expect(milestones.count).to eq(2)
        expect(milestones.first["title"]).to eq("group milestone")
        expect(milestones.second["title"]).to eq("legacy")
        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#show' do
    let(:milestone1) { create(:milestone, project: project, title: 'legacy') }
    let(:milestone2) { create(:milestone, project: project, title: 'legacy') }
    let(:group_milestone) { create(:milestone, group: group) }

    context 'when there is a title parameter' do
      it 'searchs for a legacy group milestone' do
        expect(GlobalMilestone).to receive(:build)
        expect(Milestone).not_to receive(:find_by_iid)

        get :show, group_id: group.to_param, id: title, title: milestone1.safe_title
      end
    end

    context 'when there is not a title parameter' do
      it 'searchs for a group milestone' do
        expect(GlobalMilestone).not_to receive(:build)
        expect(Milestone).to receive(:find_by_iid)

        get :show, group_id: group.to_param, id: group_milestone.id
      end
    end
  end

  it_behaves_like 'milestone tabs'

  describe "#create" do
    it "creates group milestone with Chinese title" do
      post :create,
           group_id: group.to_param,
           milestone: milestone_params

      milestone = Milestone.find_by_title(title)

      expect(response).to redirect_to(group_milestone_path(group, milestone.iid))
      expect(milestone.group_id).to eq(group.id)
      expect(milestone.due_date).to eq(milestone_params[:due_date])
      expect(milestone.start_date).to eq(milestone_params[:start_date])
    end
  end

  describe "#update" do
    let(:milestone) { create(:milestone, group: group) }

    it "updates group milestone" do
      milestone_params[:title] = "title changed"

      put :update,
           id: milestone.iid,
           group_id: group.to_param,
           milestone: milestone_params

      milestone.reload
      expect(response).to redirect_to(group_milestone_path(group, milestone.iid))
      expect(milestone.title).to eq("title changed")
    end

    context "legacy group milestones" do
      let!(:milestone1) { create(:milestone, project: project, title: 'legacy milestone', description: "old description") }
      let!(:milestone2) { create(:milestone, project: project2, title: 'legacy milestone', description: "old description") }

      it "updates only group milestones state" do
        milestone_params[:title] = "title changed"
        milestone_params[:description] = "description changed"
        milestone_params[:state_event] = "close"

        put :update,
             id: milestone1.title.to_slug.to_s,
             group_id: group.to_param,
             milestone: milestone_params,
             title: milestone1.title

        expect(response).to redirect_to(group_milestone_path(group, milestone1.safe_title, title: milestone1.title))

        [milestone1, milestone2].each do |milestone|
          milestone.reload
          expect(milestone.title).to eq("legacy milestone")
          expect(milestone.description).to eq("old description")
          expect(milestone.state).to eq("closed")
        end
      end
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting the canonical path' do
        context 'non-show path' do
          context 'with exactly matching casing' do
            it 'does not redirect' do
              get :index, group_id: group.to_param

              expect(response).not_to have_gitlab_http_status(301)
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :index, group_id: group.to_param.upcase

              expect(response).to redirect_to(group_milestones_path(group.to_param))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'show path' do
          context 'with exactly matching casing' do
            it 'does not redirect' do
              get :show, group_id: group.to_param, id: title

              expect(response).not_to have_gitlab_http_status(301)
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :show, group_id: group.to_param.upcase, id: title

              expect(response).to redirect_to(group_milestone_path(group.to_param, title))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end
      end

      context 'when requesting a redirected path' do
        let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

        it 'redirects to the canonical path' do
          get :merge_requests, group_id: redirect_route.path, id: title

          expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
          expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
        end

        context 'when the old group path is a substring of the scheme or host' do
          let(:redirect_route) { group.redirect_routes.create(path: 'http') }

          it 'does not modify the requested host' do
            get :merge_requests, group_id: redirect_route.path, id: title

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end
        end

        context 'when the old group path is substring of groups' do
          # I.e. /groups/oups should not become /grfoo/oups
          let(:redirect_route) { group.redirect_routes.create(path: 'oups') }

          it 'does not modify the /groups part of the path' do
            get :merge_requests, group_id: redirect_route.path, id: title

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end
        end

        context 'when the old group path is substring of groups plus the new path' do
          # I.e. /groups/oups/oup should not become /grfoos
          let(:redirect_route) { group.redirect_routes.create(path: 'oups/oup') }

          it 'does not modify the /groups part of the path' do
            get :merge_requests, group_id: redirect_route.path, id: title

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end
        end
      end
    end
  end

  context 'for a non-GET request' do
    context 'when requesting the canonical path with different casing' do
      it 'does not 404' do
        post :create,
             group_id: group.to_param,
             milestone: { title: title }

        expect(response).not_to have_gitlab_http_status(404)
      end

      it 'does not redirect to the correct casing' do
        post :create,
             group_id: group.to_param,
             milestone: { title: title }

        expect(response).not_to have_gitlab_http_status(301)
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'returns not found' do
        post :create,
             group_id: redirect_route.path,
             milestone: { title: title }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  def group_moved_message(redirect_route, group)
    "Group '#{redirect_route.path}' was moved to '#{group.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
