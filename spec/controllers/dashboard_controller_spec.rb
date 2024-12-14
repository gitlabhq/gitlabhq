# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardController, feature_category: :code_review_workflow do
  context 'signed in' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    before_all do
      project.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    describe 'GET issues.atom' do
      it_behaves_like 'issuables list meta-data', :issue, :issues, format: :atom
      it_behaves_like 'issuables requiring filter', :issues, format: :atom

      it 'includes tasks in issue list' do
        task = create(:work_item, :task, project: project, author: user)

        get :issues, params: { author_id: user.id }, format: :atom

        expect(assigns[:issues].map(&:id)).to include(task.id)
      end
    end

    describe 'GET merge requests' do
      it_behaves_like 'issuables list meta-data', :merge_request, :merge_requests
      it_behaves_like 'issuables requiring filter', :merge_requests

      context 'when an ActiveRecord::QueryCanceled is raised' do
        before do
          allow_next_instance_of(Gitlab::IssuableMetadata) do |instance|
            allow(instance).to receive(:data).and_raise(ActiveRecord::QueryCanceled)
          end
        end

        it 'sets :search_timeout_occurred' do
          get :merge_requests, params: { author_id: user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:search_timeout_occurred)).to eq(true)
        end

        context 'rendering views' do
          render_views

          it 'shows error message' do
            get :merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Too many results to display. Edit your search or add a filter.')
          end

          it 'does not display MR counts in nav' do
            get :merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Open Merged Closed All')
            expect(response.body).not_to have_content('Open 0 Merged 0 Closed 0 All 0')
          end
        end

        it 'logs the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          get :merge_requests, params: { author_id: user.id }
        end
      end

      context 'when an ActiveRecord::QueryCanceled is not raised' do
        it 'does not set :search_timeout_occurred' do
          get :merge_requests, params: { author_id: user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:search_timeout_occurred)).to eq(nil)
        end

        context 'rendering views' do
          render_views

          it 'displays MR counts in nav' do
            get :merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Open 0 Merged 0 Closed 0 All 0')
            expect(response.body).not_to have_content('Open Merged Closed All')
          end
        end
      end
    end

    describe 'GET merge requests search' do
      it_behaves_like 'issuables requiring filter', :search_merge_requests

      context 'when an ActiveRecord::QueryCanceled is raised' do
        before do
          allow_next_instance_of(Gitlab::IssuableMetadata) do |instance|
            allow(instance).to receive(:data).and_raise(ActiveRecord::QueryCanceled)
          end
        end

        it 'sets :search_timeout_occurred' do
          get :search_merge_requests, params: { author_id: user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:search_timeout_occurred)).to eq(true)
        end

        context 'rendering views' do
          render_views

          it 'shows error message' do
            get :search_merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Too many results to display. Edit your search or add a filter.')
          end

          it 'does not display MR counts in nav' do
            get :search_merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Open Merged Closed All')
            expect(response.body).not_to have_content('Open 0 Merged 0 Closed 0 All 0')
          end
        end

        it 'logs the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          get :search_merge_requests, params: { author_id: user.id }
        end
      end

      context 'when an ActiveRecord::QueryCanceled is not raised' do
        it 'does not set :search_timeout_occurred' do
          get :search_merge_requests, params: { author_id: user.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:search_timeout_occurred)).to eq(nil)
        end

        context 'rendering views' do
          render_views

          it 'displays MR counts in nav' do
            get :search_merge_requests, params: { author_id: user.id }

            expect(response.body).to have_content('Open 0 Merged 0 Closed 0 All 0')
            expect(response.body).not_to have_content('Open Merged Closed All')
          end
        end
      end
    end
  end

  describe "GET activity as JSON" do
    include DesignManagementTestHelpers
    render_views

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, issues_access_level: ProjectFeature::PRIVATE) }
    let_it_be(:other_project) { create(:project, :public) }

    before do
      enable_design_management
      create(:event, :created, project: project, target: create(:issue))
      create(:wiki_page_event, :created, project: project)
      create(:wiki_page_event, :updated, project: project)
      create(:design_event, project: project)
      create(:design_event, author: user, project: other_project)

      sign_in(user)

      request.cookies[:event_filter] = 'all'
    end

    context 'when user has permission to see the event' do
      before do
        project.add_developer(user)
        other_project.add_developer(user)
      end

      context 'without filter param' do
        it 'returns only events of the user' do
          get :activity, params: { format: :json }

          expect(json_response['count']).to eq(3)
        end
      end

      context 'with "projects" filter' do
        it 'returns events of the user\'s projects' do
          get :activity, params: { format: :json, filter: :projects }

          expect(json_response['count']).to eq(6)
        end
      end

      context 'with "followed" filter' do
        let_it_be(:followed_user) { create(:user) }
        let_it_be(:followed_user_private_project) { create(:project, :private) }
        let_it_be(:followed_user_public_project) { create(:project, :public) }

        before do
          followed_user_private_project.add_developer(followed_user)
          followed_user_public_project.add_developer(followed_user)
          user.follow(followed_user)
          create(:event, :created, project: followed_user_private_project, target: create(:issue),
            author: followed_user)
          create(:event, :created, project: followed_user_public_project, target: create(:issue), author: followed_user)
        end

        it 'returns public events of the user\'s followed users' do
          get :activity, params: { format: :json, filter: :followed }

          expect(json_response['count']).to eq(1)
        end
      end
    end

    context 'when user has no permission to see the event' do
      it 'filters out invisible event' do
        get :activity, params: { format: :json, filter: :projects }

        expect(json_response['html']).to include(_('No activities found'))
      end

      it 'filters out invisible event when calculating the count' do
        get :activity, params: { format: :json, filter: :projects }

        expect(json_response['count']).to eq(0)
      end
    end
  end

  describe "#check_filters_presence!" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      get :merge_requests, params: params
    end

    context "no filters" do
      let(:params) { {} }

      shared_examples_for 'no filters are set' do
        it 'sets @no_filters_set to true' do
          expect(assigns[:no_filters_set]).to eq(true)
        end
      end

      it_behaves_like 'no filters are set'

      context 'when key is present but value is not' do
        let(:params) { { author_username: nil } }

        it_behaves_like 'no filters are set'
      end

      context 'when in param is set but no search' do
        let(:params) { { in: 'title' } }

        it_behaves_like 'no filters are set'
      end
    end

    shared_examples_for 'filters are set' do
      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(false)
      end
    end

    context "scalar filters" do
      let(:params) { { author_id: user.id } }

      it_behaves_like 'filters are set'
    end

    context "array filters" do
      let(:params) { { label_name: ['bug'] } }

      it_behaves_like 'filters are set'
    end

    context 'search' do
      let(:params) { { search: 'test' } }

      it_behaves_like 'filters are set'
    end
  end
end
