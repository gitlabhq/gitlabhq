# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MilestonesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let(:title) { '肯定不是中文的问题' }

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
    project.add_maintainer(user)
  end

  it_behaves_like 'milestone tabs' do
    let(:milestone) { create(:milestone, group: group) }
    let(:milestone_path) { group_milestone_path(group, milestone.iid) }
    let(:request_params) { { group_id: group, id: milestone.iid } }
  end

  describe '#index' do
    describe 'as HTML' do
      render_views

      it 'shows group milestones page' do
        milestone

        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(milestone.title)
      end

      it 'searches legacy milestones by title when search_title is given' do
        project_milestone = create(:milestone, project: project, title: 'Project milestone title')

        get :index, params: { group_id: group.to_param, search_title: 'Project mil' }

        expect(response.body).to include(project_milestone.title)
        expect(response.body).not_to include(milestone.title)
      end

      it 'searches group milestones by title when search_title is given' do
        group_milestone = create(:milestone, title: 'Group milestone title', group: group)

        get :index, params: { group_id: group.to_param, search_title: 'Group mil' }

        expect(response.body).to include(group_milestone.title)
        expect(response.body).not_to include(milestone.title)
      end

      context 'when anonymous user' do
        before do
          sign_out(user)
        end

        it 'shows group milestones page' do
          milestone

          get :index, params: { group_id: group.to_param }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(milestone.title)
        end
      end

      context 'when issues and merge requests are disabled in public project' do
        shared_examples 'milestone not accessible' do
          it 'does not return milestone' do
            get :index, params: { group_id: public_group.to_param }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).not_to include(private_milestone.title)
          end
        end

        let_it_be(:public_group) { create(:group, :public) }

        let_it_be(:public_project_with_private_issues_and_mrs) do
          create(:project, :public, :issues_private, :merge_requests_private, group: public_group)
        end

        let_it_be(:private_milestone) { create(:milestone, project: public_project_with_private_issues_and_mrs, title: 'project milestone') }

        context 'when anonymous user' do
          before do
            sign_out(user)
          end

          it_behaves_like 'milestone not accessible'
        end

        context 'when non project or group member user' do
          let(:non_member) { create(:user) }

          before do
            sign_in(non_member)
          end

          it_behaves_like 'milestone not accessible'
        end

        context 'when group member user' do
          let(:member) { create(:user) }

          before do
            sign_in(member)
            public_group.add_guest(member)
          end

          it 'returns the milestone' do
            get :index, params: { group_id: public_group.to_param }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to include(private_milestone.title)
          end
        end
      end

      context 'when subgroup milestones are present' do
        let(:subgroup) { create(:group, :private, parent: group) }
        let(:sub_project) { create(:project, :private, group: subgroup) }
        let!(:group_milestone) { create(:milestone, group: group, title: 'Group milestone') }
        let!(:sub_project_milestone) { create(:milestone, project: sub_project, title: 'Sub Project Milestone') }
        let!(:subgroup_milestone) { create(:milestone, title: 'Subgroup Milestone', group: subgroup) }

        it 'shows subgroup milestones that user has access to' do
          get :index, params: { group_id: group.to_param }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(group_milestone.title)
          expect(response.body).to include(sub_project_milestone.title)
          expect(response.body).to include(subgroup_milestone.title)
        end

        context 'when user has no access to subgroups' do
          let(:non_member) { create(:user) }

          before do
            sign_in(non_member)
          end

          it 'does not show subgroup milestones' do
            get :index, params: { group_id: group.to_param }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to include(group_milestone.title)
            expect(response.body).not_to include(sub_project_milestone.title)
            expect(response.body).not_to include(subgroup_milestone.title)
          end
        end
      end
    end

    context 'as JSON' do
      before do
        create(:milestone, group: group, title: 'group milestone')
        create(:milestone, project: project, title: 'same name')
        create(:milestone, project: project2, title: 'same name')
      end

      it 'lists project and group milestones' do
        get :index, params: { group_id: group.to_param }, format: :json

        milestones = json_response

        expect(milestones.count).to eq(4)
        expect(milestones.collect { |m| m['title'] }).to match_array([milestone.name, 'same name', 'same name', 'group milestone'])
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq 'application/json'
      end

      context 'with subgroup milestones' do
        it 'lists descendants group milestones' do
          subgroup = create(:group, :public, parent: group)
          create(:milestone, group: subgroup, title: 'subgroup milestone')

          get :index, params: { group_id: group.to_param }, format: :json
          milestones = json_response

          milestone_titles = milestones.map { |m| m['title'] }
          expect(milestones.count).to eq(5)
          expect(milestone_titles).to match_array([milestone.name, 'same name', 'same name', 'group milestone', 'subgroup milestone'])
        end
      end

      context 'for a subgroup' do
        let(:subgroup) { create(:group, parent: group) }

        it 'includes ancestor group milestones' do
          get :index, params: { group_id: subgroup.to_param }, format: :json

          milestones = json_response

          expect(milestones.count).to eq(1)
          expect(milestones.first['title']).to eq('group milestone')
        end
      end
    end

    context 'external authorization' do
      subject { get :index, params: { group_id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe '#show' do
    render_views

    let!(:group_milestone) { create(:milestone, group: group) }

    it 'renders for a group milestone' do
      get :show, params: { group_id: group.to_param, id: group_milestone.iid }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(group_milestone.title)
    end
  end

  describe "#create" do
    it "creates group milestone with Chinese title" do
      post :create, params: {
        group_id: group.to_param,
        milestone: milestone_params
      }

      milestone = Milestone.find_by_title(title)

      expect(response).to redirect_to(group_milestone_path(group, milestone.iid))
      expect(milestone.group_id).to eq(group.id)
      expect(milestone.due_date).to eq(milestone_params[:due_date])
      expect(milestone.start_date).to eq(milestone_params[:start_date])
    end
  end

  describe "#update" do
    let_it_be_with_reload(:milestone) { create(:milestone, group: group) }

    subject do
      put :update, params: {
        id: milestone.iid,
        milestone: milestone_params,
        group_id: group.to_param
      }
    end

    it "updates group milestone" do
      milestone_params[:title] = "title changed"

      subject
      milestone.reload

      expect(response).to redirect_to(group_milestone_path(group, milestone.iid))
      expect(milestone.title).to eq("title changed")
    end

    it "handles validation error" do
      subgroup = create(:group, parent: group)
      subgroup_milestone = create(:milestone, group: subgroup)

      milestone_params[:title] = subgroup_milestone.title

      subject

      expect(response).not_to redirect_to(group_milestone_path(group, milestone.iid))
      expect(response).to render_template(:edit)
    end

    it "handles ActiveRecord::StaleObjectError" do
      milestone_params[:title] = "title changed"
      # Purposely reduce the lock_version to trigger an ActiveRecord::StaleObjectError
      milestone_params[:lock_version] = milestone.lock_version - 1

      subject

      expect(response).not_to redirect_to(group_milestone_path(group, milestone.iid))
      expect(response).to render_template(:edit)
    end

    context 'with format :json' do
      subject do
        patch :update,
          params: {
            id: milestone.iid,
            milestone: milestone_params,
            group_id: group.to_param,
            format: :json
          }
      end

      it "responds :no_content (204) without content body and updates milestone successfully" do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_blank

        milestone.reload

        expect(milestone).to have_attributes(title: milestone_params[:title])
      end

      it 'responds unprocessable_entity (422) with error data' do
        # Note: This assignment ensures and triggers a validation error when updating the milestone.
        # Same approach used in spec/models/milestone_spec.rb .
        milestone_params[:title] = '<img src=x onerror=prompt(1)>'

        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)

        expect(json_response).to include("errors" => be_an(Array))
      end

      it "handles ActiveRecord::StaleObjectError" do
        milestone_params[:title] = "title changed"
        # Purposely reduce the `lock_version` to trigger an ActiveRecord::StaleObjectError
        milestone_params[:lock_version] = milestone.lock_version - 1

        subject

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response).to include "errors" => [
          format(
            _("Someone edited this %{model_name} at the same time you did. Please refresh your browser and make sure your changes will not unintentionally remove theirs."),
            model_name: _('milestone')
          )
        ]
      end
    end
  end

  describe "#destroy" do
    let(:milestone) { create(:milestone, group: group) }

    it "removes milestone" do
      delete :destroy, params: { group_id: group.to_param, id: milestone.iid }, format: :js

      expect(response).to be_successful
      expect { Milestone.find(milestone.id) }.to raise_exception(ActiveRecord::RecordNotFound)
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
              get :index, params: { group_id: group.to_param }

              expect(response).not_to have_gitlab_http_status(:moved_permanently)
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :index, params: { group_id: group.to_param.upcase }

              expect(response).to redirect_to(group_milestones_path(group.to_param))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'show path' do
          context 'with exactly matching casing' do
            it 'does not redirect' do
              get :show, params: { group_id: group.to_param, id: title }

              expect(response).not_to have_gitlab_http_status(:moved_permanently)
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :show, params: { group_id: group.to_param.upcase, id: title }

              expect(response).to redirect_to(group_milestone_path(group.to_param, title))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end
      end

      context 'when requesting a redirected path' do
        let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }

        it 'redirects to the canonical path' do
          get :merge_requests, params: { group_id: redirect_route.path, id: title }

          expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
          expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
        end

        context 'with an AJAX request' do
          it 'redirects to the canonical path but does not set flash message' do
            get :merge_requests, params: { group_id: redirect_route.path, id: title }, xhr: true

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).not_to set_flash[:notice]
          end
        end

        context 'with JSON format' do
          it 'redirects to the canonical path but does not set flash message' do
            get :merge_requests, params: { group_id: redirect_route.path, id: title }, format: :json

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title, format: :json))
            expect(controller).not_to set_flash[:notice]
          end
        end

        context 'when the old group path is a substring of the scheme or host' do
          let(:redirect_route) { group.redirect_routes.create!(path: 'http') }

          it 'does not modify the requested host' do
            get :merge_requests, params: { group_id: redirect_route.path, id: title }

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end
        end

        context 'when the old group path is substring of groups' do
          # I.e. /groups/oups should not become /grfoo/oups
          let(:redirect_route) { group.redirect_routes.create!(path: 'oups') }

          it 'does not modify the /groups part of the path' do
            get :merge_requests, params: { group_id: redirect_route.path, id: title }

            expect(response).to redirect_to(merge_requests_group_milestone_path(group.to_param, title))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end
        end

        context 'when the old group path is substring of groups plus the new path' do
          # I.e. /groups/oups/oup should not become /grfoos
          let(:redirect_route) { group.redirect_routes.create!(path: 'oups/oup') }

          it 'does not modify the /groups part of the path' do
            get :merge_requests, params: { group_id: redirect_route.path, id: title }

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
        post :create, params: {
          group_id: group.to_param,
          milestone: { title: title }
        }

        expect(response).not_to have_gitlab_http_status(:not_found)
      end

      it 'does not redirect to the correct casing' do
        post :create, params: {
          group_id: group.to_param,
          milestone: { title: title }
        }

        expect(response).not_to have_gitlab_http_status(:moved_permanently)
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }

      it 'returns not found' do
        post :create, params: {
          group_id: redirect_route.path,
          milestone: { title: title }
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def group_moved_message(redirect_route, group)
    "Group '#{redirect_route.path}' was moved to '#{group.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
