# frozen_string_literal: true

require 'spec_helper'

describe Projects::UsagePingController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe 'POST #web_ide_clientside_preview' do
    subject { post :web_ide_clientside_preview, params: { namespace_id: project.namespace, project_id: project } }

    before do
      sign_in(user) if user
    end

    context 'when web ide clientside preview is enabled' do
      before do
        stub_application_setting(web_ide_clientside_preview_enabled: true)
      end

      context 'when the user is not authenticated' do
        let(:user) { nil }

        it 'returns 302' do
          subject

          expect(response).to have_gitlab_http_status(302)
        end
      end

      context 'when the user does not have access to the project' do
        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when the user has access to the project' do
        let(:user) { project.owner }

        it 'increments the counter' do
          expect do
            subject
          end.to change { Gitlab::UsageDataCounters::WebIdeCounter.total_previews_count }.by(1)
        end
      end
    end

    context 'when web ide clientside preview is not enabled' do
      let(:user) { project.owner }

      before do
        stub_application_setting(web_ide_clientside_preview_enabled: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
