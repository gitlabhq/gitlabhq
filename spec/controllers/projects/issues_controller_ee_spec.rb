require('spec_helper')

describe Projects::IssuesController do
  let(:namespace) { create(:namespace) }
  let(:project)   { create(:project_empty_repo, namespace: namespace) }
  let(:user)      { create(:user) }
  let(:viewer)    { user }
  let(:issue)     { create(:issue, project: project) }

  describe 'POST export_csv' do
    let(:globally_licensed) { false }

    before do
      project.add_developer(user)

      sign_in(viewer) if viewer

      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:export_issues).and_return(globally_licensed)
    end

    def request_csv
      post :export_csv, namespace_id: project.namespace.to_param, project_id: project.to_param
    end

    context 'unlicensed' do
      it 'returns 404' do
        expect(ExportCsvWorker).not_to receive(:perform_async)

        request_csv

        expect(response.status).to eq(404)
      end
    end

    context 'globally licensed' do
      let(:globally_licensed) { true }

      it 'allows CSV export' do
        expect(ExportCsvWorker).to receive(:perform_async).with(viewer.id, project.id, anything)

        request_csv

        expect(response).to redirect_to(namespace_project_issues_path(project.namespace, project))
        expect(response.flash[:notice]).to match(/\AYour CSV export has started/i)
      end

      context 'anonymous user' do
        let(:project) { create(:project_empty_repo, :public, namespace: namespace) }
        let(:viewer) { nil }

        it 'redirects to the sign in page' do
          request_csv

          expect(ExportCsvWorker).not_to receive(:perform_async)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'licensed by namespace' do
      let(:globally_licensed) { true }
      let(:namespace) { create(:group, :private, plan: Namespace::BRONZE_PLAN) }

      before do
        stub_application_setting(check_namespace_plan: true)
      end

      it 'allows CSV export' do
        expect(ExportCsvWorker).to receive(:perform_async).with(viewer.id, project.id, anything)

        request_csv

        expect(response).to redirect_to(namespace_project_issues_path(project.namespace, project))
        expect(response.flash[:notice]).to match(/\AYour CSV export has started/i)
      end
    end
  end
end
