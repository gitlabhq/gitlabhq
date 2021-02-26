# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::ProjectsController do
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
        it 'avoids N+1 queries' do
          projects = create_list(:project, 3, :repository, :public)
          projects.each do |project|
            pipeline = create(:ci_pipeline, :success, project: project, sha: project.commit.id)
            create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)
          end

          control = ActiveRecord::QueryRecorder.new { get endpoint }

          new_projects = create_list(:project, 2, :repository, :public)
          new_projects.each do |project|
            pipeline = create(:ci_pipeline, :success, project: project, sha: project.commit.id)
            create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)
          end

          expect { get endpoint }.not_to exceed_query_limit(control).with_threshold(8)
        end
      end
    end
  end

  context 'when user is signed in' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
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
  end

  context 'when user is not signed in' do
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
  end
end
