# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController, :aggregate_failures, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }

  describe '#index' do
    context 'user logged in' do
      let_it_be(:project) { create(:project, name: 'Project 1') }
      let_it_be(:project2) { create(:project, name: 'Project Two') }

      let(:projects) { [project, project2] }

      before_all do
        project.add_developer(user)
        project2.add_developer(user)
        user.toggle_star(project2)
      end

      before do
        stub_feature_flags(your_work_projects_vue: false)
        sign_in(user)
      end

      context 'external authorization' do
        it 'works when the external authorization service is enabled' do
          enable_external_authorization_service_check

          get :index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it 'orders the projects by name by default' do
        get :index

        expect(assigns(:projects)).to eq(projects)
      end

      it 'assigns the correct all_user_projects' do
        get :index
        all_user_projects = assigns(:all_user_projects)

        expect(all_user_projects.count).to eq(2)
      end

      it 'assigns the correct all_starred_projects' do
        get :index
        all_starred_projects = assigns(:all_starred_projects)

        expect(all_starred_projects.count).to eq(1)
        expect(all_starred_projects).to include(project2)
      end

      context 'project sorting' do
        it_behaves_like 'set sort order from user preference' do
          let(:sorting_param) { 'created_asc' }
        end
      end

      context 'with search and sort parameters' do
        render_views

        shared_examples 'search and sort parameters' do |sort|
          it 'returns a single project with no ambiguous column errors' do
            get :index, params: { name: project2.name, sort: sort }

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:projects)).to eq([project2])
          end
        end

        %w[latest_activity_desc latest_activity_asc stars_desc stars_asc created_desc].each do |sort|
          it_behaves_like 'search and sort parameters', sort
        end
      end

      context 'with archived project' do
        let_it_be(:archived_project) do
          project2.tap { |p| p.update!(archived: true) }
        end

        it 'does not display archived project' do
          get :index
          projects_result = assigns(:projects)

          expect(projects_result).not_to include(archived_project)
          expect(projects_result).to include(project)
        end

        it 'excludes archived project from all_user_projects' do
          get :index
          all_user_projects = assigns(:all_user_projects)

          expect(all_user_projects.count).to eq(1)
          expect(all_user_projects).not_to include(archived_project)
        end

        it 'excludes archived project from all_starred_projects' do
          get :index
          all_starred_projects = assigns(:all_starred_projects)

          expect(all_starred_projects.count).to eq(0)
          expect(all_starred_projects).not_to include(archived_project)
        end
      end

      context 'with deleted project' do
        let!(:pending_delete_project) do
          project.tap { |p| p.update!(pending_delete: true) }
        end

        it 'does not display deleted project' do
          get :index
          projects_result = assigns(:projects)

          expect(projects_result).not_to include(pending_delete_project)
          expect(projects_result).to include(project2)
        end
      end

      context 'with redirects' do
        context 'when feature flag your_work_projects_vue is true' do
          before do
            stub_feature_flags(your_work_projects_vue: true)
          end

          it 'redirects ?personal=true to /personal' do
            get :index, params: { personal: true }

            expect(response).to redirect_to(personal_dashboard_projects_path)
          end

          it 'redirects ?archived=only to /inactive' do
            get :index, params: { archived: 'only' }

            expect(response).to redirect_to(inactive_dashboard_projects_path)
          end
        end

        it 'does not redirect ?personal=true to /personal' do
          get :index, params: { personal: true }

          expect(response).not_to redirect_to(personal_dashboard_projects_path)
        end

        it 'does not ?archived=only to /inactive' do
          get :index, params: { archived: 'only' }

          expect(response).not_to redirect_to(inactive_dashboard_projects_path)
        end
      end
    end
  end

  context 'json requests' do
    render_views

    before do
      stub_feature_flags(your_work_projects_vue: false)
      sign_in(user)
    end

    describe 'GET /projects.json' do
      before do
        get :index, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET /starred.json' do
      subject { get :starred, format: :json }

      let(:projects) { create_list(:project, 2, creator: user) }
      let(:aimed_for_deletion_project) { create_list(:project, 2, :archived, creator: user, marked_for_deletion_at: 3.days.ago) }

      before do
        projects.each do |project|
          project.add_developer(user)
          create(:users_star_project, project_id: project.id, user_id: user.id)
        end

        aimed_for_deletion_project.each do |project|
          project.add_developer(user)
          create(:users_star_project, project_id: project.id, user_id: user.id)
        end
      end

      it 'returns success' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      context "pagination" do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)
        end

        it 'paginates the records' do
          subject

          expect(assigns(:projects).count).to eq(1)
        end
      end

      it 'does not include projects aimed for deletion' do
        subject

        expect(assigns(:projects).count).to eq(2)
      end
    end
  end

  context 'atom requests' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
      sign_in(user)
    end

    describe '#index' do
      let_it_be(:projects) { create_list(:project, 2, creator: user) }

      context 'project pagination' do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)

          projects.each do |project|
            project.add_developer(user)
          end
        end

        it 'does not paginate projects, even if normally restricted by pagination' do
          get :index, format: :atom

          expect(assigns(:events).count).to eq(2)
        end
      end

      describe 'rendering' do
        include DesignManagementTestHelpers
        render_views

        let(:project) { projects.first }
        let!(:design_event) { create(:design_event, project: project) }
        let!(:wiki_page_event) { create(:wiki_page_event, project: project) }
        let!(:issue_event) { create(:closed_issue_event, project: project) }
        let!(:push_event) do
          create(:push_event, project: project).tap do |event|
            create(:push_event_payload, event: event, ref_count: 2, ref: nil, ref_type: :tag, commit_count: 0, action: :pushed)
          end
        end

        let(:design) { design_event.design }
        let(:wiki_page) { wiki_page_event.wiki_page }
        let(:issue) { issue_event.issue }

        before do
          enable_design_management
          project.add_developer(user)
        end

        it 'renders all kinds of event without error' do
          get :index, format: :atom

          expect(assigns(:events)).to include(design_event, wiki_page_event, issue_event, push_event)
          expect(response).to render_template('dashboard/projects/index')
          expect(response.body).to include(
            "pushed to project",
            "added design #{design.to_reference}",
            "created wiki page #{wiki_page.title}",
            "joined project #{project.full_name}",
            "closed issue #{issue.to_reference}"
          )
        end

        context 'with deleted project' do
          let(:pending_deleted_project) { projects.last.tap { |p| p.update!(pending_delete: true) } }

          before do
            pending_deleted_project.add_developer(user)
          end

          it 'does not display deleted project' do
            get :index, format: :atom

            expect(response.body).not_to include(pending_deleted_project.full_name)
            expect(response.body).to include(project.full_name)
          end
        end
      end
    end
  end

  describe '#starred' do
    let_it_be(:project) { create(:project, name: 'Project 1') }
    let_it_be(:project2) { create(:project, name: 'Project Two') }

    before_all do
      project.add_developer(user)
      project2.add_developer(user)
      user.toggle_star(project2)
    end

    context 'when your_work_projects_vue feature flag is enabled' do
      before do
        sign_in(user)
      end

      it 'does not assign all_starred_projects' do
        get :starred

        expect(assigns(:all_starred_projects)).to be_nil
      end
    end

    context 'when your_work_projects_vue feature flag is disabled' do
      before do
        stub_feature_flags(your_work_projects_vue: false)
        sign_in(user)
      end

      it 'assigns all_starred_projects' do
        get :starred

        expect(assigns(:all_starred_projects)).to contain_exactly(project2)
      end
    end
  end
end
