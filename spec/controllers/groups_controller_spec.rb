# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, factory_default: :keep, feature_category: :code_review_workflow do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper
  include Namespaces::DeletableHelper
  include ActionView::Helpers::TagHelper
  include SafeFormatHelper

  let_it_be(:group_organization) { current_organization }
  let_it_be_with_refind(:group) { create_default(:group, :public, organization: group_organization) }
  let_it_be_with_refind(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin_with_admin_mode) { create(:admin) }
  let_it_be(:admin_without_admin_mode) { create(:admin) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be_with_reload(:owner) { group.add_owner(create(:user)).user }
  let_it_be(:maintainer) { group.add_maintainer(create(:user)).user }
  let_it_be_with_reload(:developer) { group.add_developer(create(:user)).user }
  let_it_be(:guest) { group.add_guest(create(:user)).user }

  before_all do
    group_organization.users = User.all
  end

  before do
    enable_admin_mode!(admin_with_admin_mode)
  end

  describe 'POST #export' do
    context 'when the user does not have permission to export the group' do
      before do
        sign_in(guest)
      end

      it 'returns an error' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user has permission to export the group' do
      before do
        sign_in(user)
      end

      it 'triggers the export job' do
        expect(GroupExportWorker).to receive(:perform_async).with(user.id, group.id, { exported_by_admin: false })

        post :export, params: { id: group.to_param }
      end

      it 'redirects to the edit page' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when user is admin' do
      before do
        sign_in(admin_with_admin_mode)
      end

      it 'triggers the export job, and passes `exported_by_admin` correctly in the `params` hash' do
        expect(GroupExportWorker).to receive(:perform_async).with(admin_with_admin_mode.id, group.id, { exported_by_admin: true })

        post :export, params: { id: group.to_param }
      end
    end

    context 'when the endpoint receives requests above the rate limit' do
      before do
        sign_in(user)

        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:group_export, scope: anything).and_return(true)
      end

      it 'throttles the endpoint' do
        post :export, params: { id: group.to_param }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'GET #download_export' do
    let(:admin) { create(:admin) }
    let(:export_file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

    before do
      enable_admin_mode!(admin)
    end

    context 'when there is a file available to download' do
      before do
        sign_in(admin)
        create(:import_export_upload, group: group, export_file: export_file, user: admin)
      end

      it 'sends the file' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq export_file.tempfile.read
      end
    end

    context 'when the file is no longer present on disk' do
      before do
        sign_in(admin)

        create(:import_export_upload, group: group, export_file: export_file, user: admin)
        group.export_file(admin).file.delete
      end

      it 'returns not found' do
        get :download_export, params: { id: group.to_param }

        expect(flash[:alert]).to include('file containing the export is not available yet')
        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when there is no file available to download' do
      before do
        sign_in(admin)
      end

      it 'returns not found' do
        get :download_export, params: { id: group.to_param }

        expect(flash[:alert])
          .to eq 'Group export link has expired. Please generate a new export from your group settings.'

        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when the user does not have the required permissions' do
      before do
        sign_in(guest)
      end

      it 'returns not_found' do
        get :download_export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the endpoint receives requests above the rate limit' do
      before do
        sign_in(admin)

        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:group_download_export, scope: [admin, group]).and_return(true)
      end

      it 'throttles the endpoint' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'external authorization' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    describe "GET #activity as JSON" do
      include DesignManagementTestHelpers

      let(:other_project) { create(:project, :public, group: group) }

      def get_activity
        get :activity, params: { format: :json, id: group.to_param }
      end

      before do
        enable_design_management
        issue = create(:issue, project: project)
        create(:event, :created, project: project, target: issue)
        create(:design_event, project: project)
        create(:design_event, project: other_project)

        sign_in(user)

        request.cookies[:event_filter] = 'all'
      end

      it 'returns count' do
        get_activity

        expect(json_response['count']).to eq(3)
      end

      # Guards against silent drift: the permitted list in event_projects_finder_params is
      # hand-maintained, so a dropped or wrongly-typed key would stop filtering without error.
      it 'forwards every permitted filter to the project finder', :aggregate_failures do
        scalar_filters = {
          visibility_level: '20', topic: 'topic', topic_id: '1', personal: 'true', search: 'q',
          non_archived: 'true', archived: 'true', owned: 'true', non_public: 'true',
          min_access_level: '30', starred: 'true', with_issues_enabled: 'true',
          with_merge_requests_enabled: 'true', namespace_path: 'g', include_pending_delete: 'true',
          id_after: '1', id_before: '9', marked_for_deletion_on: '2026-01-01',
          aimed_for_deletion: 'true', not_aimed_for_deletion: 'true',
          last_activity_after: '2026-01-01', last_activity_before: '2026-02-01',
          repository_storage: 'default', language_name: 'Ruby', active: 'true',
          last_repository_check_failed: 'true', with_security_reports: 'true',
          include_hidden: 'true', duo_licensed_feature: 'x',
          filter_expired_saml_session_projects: 'true', name: 'n',
          minimum_search_length: '3', search_namespaces: 'true',
          updated_before: '2026-02-01', updated_after: '2026-01-01'
        }
        array_filters = {
          full_paths: ['g/p'], plans: ['ultimate'], feature_available: ['x'],
          custom_attributes: { 'k' => 'v' }
        }

        captured = nil
        allow(GroupProjectsFinder).to receive(:new).and_wrap_original do |original, **kwargs|
          captured = kwargs[:params]
          original.call(**kwargs)
        end

        get :activity, params: { format: :json, id: group.to_param }
                         .merge(scalar_filters).merge(array_filters)

        captured = captured.to_h.symbolize_keys
        scalar_filters.each { |key, value| expect(captured[key]).to eq(value) }
        array_filters.each { |key, value| expect(captured[key]).to eq(value) }
      end
    end
  end
end
