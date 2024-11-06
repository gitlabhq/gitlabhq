# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::ProjectsController, :with_current_organization, feature_category: :groups_and_projects do
  shared_examples 'explore projects' do
    let(:expected_default_sort) { 'latest_activity_desc' }

    describe 'GET #index.json' do
      render_views

      before do
        get :index, format: :json
      end

      it { is_expected.to respond_with(:success) }

      it 'sets a default sort parameter' do
        expect(controller.params[:sort]).to eq(expected_default_sort)
        expect(assigns[:sort]).to eq(expected_default_sort)
      end
    end

    describe 'GET #trending.json' do
      render_views

      before do
        get :trending, format: :json
      end

      it { is_expected.to respond_with(:success) }

      it 'sets a default sort parameter' do
        expect(controller.params[:sort]).to eq(expected_default_sort)
        expect(assigns[:sort]).to eq(expected_default_sort)
      end
    end

    describe 'GET #starred.json' do
      render_views

      before do
        get :starred, format: :json
      end

      it { is_expected.to respond_with(:success) }

      it 'sets a default sort parameter' do
        expect(controller.params[:sort]).to eq(expected_default_sort)
        expect(assigns[:sort]).to eq(expected_default_sort)
      end
    end

    describe 'GET #trending' do
      context 'sorting by update date' do
        let(:project1) { create(:project, :public, updated_at: 3.days.ago) }
        let(:project2) { create(:project, :public, updated_at: 1.day.ago) }

        before do
          create(:trending_project, project: project1)
          create(:trending_project, project: project2)
        end

        it 'sorts by last updated' do
          get :trending, params: { sort: 'updated_desc' }

          expect(assigns(:projects)).to eq [project2, project1]
        end

        it 'sorts by oldest updated' do
          get :trending, params: { sort: 'updated_asc' }

          expect(assigns(:projects)).to eq [project1, project2]
        end
      end

      context 'projects aimed for deletion' do
        let_it_be(:project1) { create(:project, :public, path: 'project-1') }
        let_it_be(:project2) { create(:project, :public, path: 'project-2') }
        let_it_be(:aimed_for_deletion_project) { create(:project, :public, :archived, marked_for_deletion_at: 2.days.ago) }

        before do
          create(:trending_project, project: project1)
          create(:trending_project, project: project2)
          create(:trending_project, project: aimed_for_deletion_project)
        end

        it 'does not list projects aimed for deletion' do
          get :trending

          expect(assigns(:projects)).to eq [project2, project1]
        end
      end
    end

    describe 'GET #topic' do
      context 'when topic does not exist' do
        it 'renders a 404 error' do
          get :topic, params: { topic_name: 'topic1' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when topic exists' do
        before do
          create(:topic, name: 'topic1', organization: current_organization)
        end

        it 'renders the template' do
          get :topic, params: { topic_name: 'topic1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('topic')
        end

        it 'finds topic by case insensitive name' do
          get :topic, params: { topic_name: 'TOPIC1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('topic')
        end
      end
    end

    describe 'GET #topic.atom' do
      context 'when topic does not exist' do
        it 'renders a 404 error' do
          get :topic, format: :atom, params: { topic_name: 'topic1' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when topic exists' do
        let_it_be(:topic) { create(:topic, name: 'topic1', organization: current_organization) }

        let(:older_project) { create(:project, :public, updated_at: 1.day.ago, namespace: namespace, topic_list: 'topic1') }
        let(:newer_project) { create(:project, :public, updated_at: 2.days.ago, namespace: namespace, topic_list: 'topic1') }

        it 'renders the template' do
          get :topic, format: :atom, params: { topic_name: 'topic1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('topic', layout: :xml)
        end

        it 'sorts repos by descending creation date' do
          get :topic, format: :atom, params: { topic_name: 'topic1' }

          expect(assigns(:projects)).to match_array [newer_project, older_project]
        end

        it 'finds topic by case insensitive name' do
          get :topic, format: :atom, params: { topic_name: 'TOPIC1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('topic', layout: :xml)
        end

        describe 'when topic contains more than 20 projects' do
          before do
            create_list(:project, 22, :public, topics: [topic])
          end

          it 'does not assigns more than 20 projects' do
            get :topic, format: :atom, params: { topic_name: 'topic1' }

            expect(assigns(:projects).count).to be(20)
          end
        end
      end
    end
  end

  shared_examples "blocks high page numbers" do
    let(:page_limit) { described_class::PAGE_LIMIT }

    context "page number is too high" do
      [:index, :trending, :starred].each do |endpoint|
        describe "GET #{endpoint}" do
          render_views

          before do
            get endpoint, params: { page: page_limit + 1 }
          end

          it { is_expected.to respond_with(:bad_request) }
          it { is_expected.to render_template("explore/projects/page_out_of_bounds") }

          it "assigns the page number" do
            expect(assigns[:max_page_number]).to eq(page_limit.to_s)
          end
        end

        describe "GET #{endpoint}.json" do
          render_views

          before do
            get endpoint, params: { page: page_limit + 1 }, format: :json
          end

          it { is_expected.to respond_with(:bad_request) }
        end

        describe "metrics recording" do
          subject { get endpoint, params: { page: page_limit + 1 } }

          let(:counter) { double("counter", increment: true) }

          before do
            allow(Gitlab::Metrics).to receive(:counter) { counter }
          end

          it "records the interception" do
            expect(Gitlab::Metrics).to receive(:counter).with(
              :gitlab_page_out_of_bounds,
              controller: "explore/projects",
              action: endpoint.to_s,
              bot: false
            )

            subject
          end
        end
      end
    end

    context "page number is acceptable" do
      [:index, :trending, :starred].each do |endpoint|
        describe "GET #{endpoint}" do
          render_views

          before do
            get endpoint, params: { page: page_limit }
          end

          it { is_expected.to respond_with(:success) }
          it { is_expected.to render_template("explore/projects/#{endpoint}") }
        end

        describe "GET #{endpoint}.json" do
          render_views

          before do
            get endpoint, params: { page: page_limit }, format: :json
          end

          it { is_expected.to respond_with(:success) }
        end
      end
    end
  end

  shared_examples 'avoids N+1 queries' do
    [:index, :trending, :starred].each do |endpoint|
      describe "GET #{endpoint}" do
        render_views

        # some N+1 queries still exist
        it 'avoids N+1 queries', :request_store do
          # Because we enable the request store for this spec, Gitaly may report too many invocations.
          # Allow N+1s here and when creating additional objects below because we're just creating test objects.
          Gitlab::GitalyClient.allow_n_plus_1_calls do
            projects = create_list(:project, 3, :repository, :public)

            projects.each do |project|
              pipeline = create(:ci_pipeline, :success, project: project, sha: project.commit.id)
              create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)
            end
          end

          control = ActiveRecord::QueryRecorder.new { get endpoint }

          Gitlab::GitalyClient.allow_n_plus_1_calls do
            new_projects = create_list(:project, 2, :repository, :public)
            new_projects.each do |project|
              pipeline = create(:ci_pipeline, :success, project: project, sha: project.commit.id)
              create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)
            end
          end

          expect { get endpoint }.not_to exceed_query_limit(control).with_threshold(8)
        end
      end
    end
  end

  context 'when user is signed in' do
    let_it_be(:namespace) { create(:namespace, organization: current_organization) }
    let_it_be(:user) { create(:user, namespace: namespace) }
    let_it_be(:project) { create(:project, name: 'Project 1', namespace: namespace) }
    let_it_be(:project2) { create(:project, name: 'Project 2', namespace: namespace) }

    before do
      sign_in(user)
      project.add_developer(user)
      project2.add_developer(user)
      user.toggle_star(project2)
    end

    include_examples 'explore projects'
    include_examples "blocks high page numbers"
    include_examples 'avoids N+1 queries'

    context 'user preference sorting' do
      let(:project) { create(:project) }

      it_behaves_like 'set sort order from user preference' do
        let(:sorting_param) { 'created_asc' }
      end
    end

    describe 'GET #index' do
      let(:controller_action) { :index }
      let(:params_with_name) { { name: 'some project' } }

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

      context 'when disable_anonymous_project_search is enabled' do
        before do
          stub_feature_flags(disable_anonymous_project_search: true)
        end

        it 'does not show a flash message' do
          sign_in(create(:user))
          get controller_action, params: params_with_name

          expect(flash.now[:notice]).to be_nil
        end
      end
    end
  end

  context 'when user is not signed in' do
    let_it_be(:namespace) { create(:namespace, organization: current_organization) }

    include_examples 'explore projects'
    include_examples "blocks high page numbers"
    include_examples 'avoids N+1 queries'

    context 'user preference sorting' do
      let(:project) { create(:project) }
      let(:sorting_param) { 'created_asc' }

      it 'does not set sort order from user preference' do
        expect_any_instance_of(UserPreference).not_to receive(:update)

        get :index, params: { sort: sorting_param }
      end
    end

    context 'restricted visibility level is public' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'redirects to login page' do
        get :index

        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'GET #index' do
      let(:controller_action) { :index }
      let(:params_with_name) { { name: 'some project' } }

      context 'when disable_anonymous_project_search is enabled' do
        before do
          stub_feature_flags(disable_anonymous_project_search: true)
        end

        it 'shows a flash message' do
          get controller_action, params: params_with_name

          expect(flash.now[:notice]).to eq('You must sign in to search for specific projects.')
        end

        context 'when search param is not given' do
          it 'does not show a flash message' do
            get controller_action

            expect(flash.now[:notice]).to be_nil
          end
        end

        context 'when format is not HTML' do
          it 'does not show a flash message' do
            get controller_action, params: params_with_name.merge(format: :atom)

            expect(flash.now[:notice]).to be_nil
          end
        end
      end

      context 'when disable_anonymous_project_search is disabled' do
        before do
          stub_feature_flags(disable_anonymous_project_search: false)
        end

        it 'does not show a flash message' do
          get controller_action, params: params_with_name

          expect(flash.now[:notice]).to be_nil
        end
      end
    end
  end
end
