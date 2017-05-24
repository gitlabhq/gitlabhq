require 'spec_helper'

describe Groups::MilestonesController do
  let(:group) { create(:group) }
  let(:project) { create(:empty_project, group: group) }
  let(:project2) { create(:empty_project, group: group) }
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

  before do
    sign_in(user)
    group.add_owner(user)
    project.team << [user, :master]
  end

  it_behaves_like 'milestone tabs'

  describe "#create" do
    it "creates group milestone with Chinese title" do
      post :create,
           group_id: group.to_param,
           milestone: { project_ids: [project.id, project2.id], title: title }

      expect(response).to redirect_to(group_milestone_path(group, title.to_slug.to_s, title: title))
      expect(Milestone.where(title: title).count).to eq(2)
    end

    it "redirects to new when there are no project ids" do
      post :create, group_id: group.to_param, milestone: { title: title, project_ids: [""] }
      expect(response).to render_template :new
      expect(assigns(:milestone).errors).not_to be_nil
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

              expect(response).not_to have_http_status(301)
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

              expect(response).not_to have_http_status(301)
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
             milestone: { project_ids: [project.id, project2.id], title: title }

        expect(response).not_to have_http_status(404)
      end

      it 'does not redirect to the correct casing' do
        post :create,
             group_id: group.to_param,
             milestone: { project_ids: [project.id, project2.id], title: title }

        expect(response).not_to have_http_status(301)
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'returns not found' do
        post :create,
             group_id: redirect_route.path,
             milestone: { project_ids: [project.id, project2.id], title: title }

        expect(response).to have_http_status(404)
      end
    end
  end

  def group_moved_message(redirect_route, group)
    "Group '#{redirect_route.path}' was moved to '#{group.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
