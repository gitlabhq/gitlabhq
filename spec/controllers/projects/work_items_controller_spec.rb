# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WorkItemsController, feature_category: :team_planning do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, reporters: reporter, guests: guest) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:file) { 'file' }

  shared_examples 'response with 404 status' do
    it 'renders a not found message' do
      expect(WorkItems::ImportWorkItemsCsvWorker).not_to receive(:perform_async)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'redirects to new session path' do
    it 'redirects to sign in' do
      subject

      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET show' do
    specify do
      expect(
        get(:show, params: { namespace_id: project.namespace, project_id: project, iid: work_item.iid })
      ).to have_request_urgency(:low)
    end
  end

  describe 'POST authorize' do
    subject do
      post(:authorize, params: { namespace_id: project.namespace, project_id: project, file: file })
    end

    specify do
      expect(subject).to have_request_urgency(:high)
    end

    context 'when user is anonymous' do
      it_behaves_like 'redirects to new session path'
    end
  end

  describe 'POST import_csv' do
    subject { post :import_csv, params: { namespace_id: project.namespace, project_id: project, file: file } }

    let(:upload_service) { double }
    let(:uploader) { double }
    let(:upload) { double }
    let(:upload_id) { 99 }

    specify do
      expect(subject).to have_request_urgency(:low)
    end

    context 'with authorized user' do
      before do
        sign_in(reporter)
        allow(controller).to receive(:file_is_valid?).and_return(true)
      end

      context 'when feature is available' do
        context 'when the upload is processed successfully' do
          before do
            mock_upload
          end

          it 'renders the correct message' do
            expect(WorkItems::ImportWorkItemsCsvWorker).to receive(:perform_async)
                                                             .with(reporter.id, project.id, upload_id)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['message']).to eq(
              "Your work items are being imported. Once finished, you'll receive a confirmation email."
            )
          end
        end

        context 'when file is not valid' do
          before do
            allow(controller).to receive(:file_is_valid?).and_return(false)
          end

          it 'renders the error message' do
            expect(WorkItems::ImportWorkItemsCsvWorker).not_to receive(:perform_async)

            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['errors'])
              .to eq('The uploaded file was invalid. Supported file extensions are .csv.')
          end
        end

        context 'when service response includes errors' do
          before do
            mock_upload(false)
          end

          it 'renders the error message' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['errors']).to eq('File upload error.')
          end
        end
      end

      context 'when feature is not available' do
        before do
          stub_feature_flags(import_export_work_items_csv: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    context 'with unauthorised user' do
      before do
        mock_upload
        sign_in(guest)
        allow(controller).to receive(:file_is_valid?).and_return(true)
      end

      it_behaves_like 'response with 404 status'
    end

    context 'with anonymous user' do
      it 'redirects to sign in page' do
        expect(WorkItems::ImportWorkItemsCsvWorker).not_to receive(:perform_async)

        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
