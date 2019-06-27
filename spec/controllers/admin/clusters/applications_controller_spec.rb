# frozen_string_literal: true

require 'spec_helper'

describe Admin::Clusters::ApplicationsController do
  include AccessMatchersForController

  def current_application
    Clusters::Cluster::APPLICATIONS[application]
  end

  shared_examples 'a secure endpoint' do
    it { expect { subject }.to be_allowed_for(:admin) }
    it { expect { subject }.to be_denied_for(:user) }
    it { expect { subject }.to be_denied_for(:external) }
  end

  let(:cluster) { create(:cluster, :instance, :provided_by_gcp) }

  describe 'POST create' do
    subject do
      post :create, params: params
    end

    let(:application) { 'helm' }
    let(:params) { { application: application, id: cluster.id } }

    describe 'functionality' do
      let(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      it 'schedule an application installation' do
        expect(ClusterInstallAppWorker).to receive(:perform_async).with(application, anything).once

        expect { subject }.to change { current_application.count }
        expect(response).to have_http_status(:no_content)
        expect(cluster.application_helm).to be_scheduled
      end

      context 'when cluster do not exists' do
        before do
          cluster.destroy!
        end

        it 'return 404' do
          expect { subject }.not_to change { current_application.count }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when application is unknown' do
        let(:application) { 'unkwnown-app' }

        it 'return 404' do
          is_expected.to have_http_status(:not_found)
        end
      end

      context 'when application is already installing' do
        before do
          create(:clusters_applications_helm, :installing, cluster: cluster)
        end

        it 'returns 400' do
          is_expected.to have_http_status(:bad_request)
        end
      end
    end

    describe 'security' do
      before do
        allow(ClusterInstallAppWorker).to receive(:perform_async)
      end

      it_behaves_like 'a secure endpoint'
    end
  end

  describe 'PATCH update' do
    subject do
      patch :update, params: params
    end

    let!(:application) { create(:clusters_applications_cert_managers, :installed, cluster: cluster) }
    let(:application_name) { application.name }
    let(:params) { { application: application_name, id: cluster.id, email: "new-email@example.com" } }

    describe 'functionality' do
      let(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context "when cluster and app exists" do
        it "schedules an application update" do
          expect(ClusterPatchAppWorker).to receive(:perform_async).with(application.name, anything).once

          is_expected.to have_http_status(:no_content)

          expect(cluster.application_cert_manager).to be_scheduled
        end
      end

      context 'when cluster do not exists' do
        before do
          cluster.destroy!
        end

        it { is_expected.to have_http_status(:not_found) }
      end

      context 'when application is unknown' do
        let(:application_name) { 'unkwnown-app' }

        it { is_expected.to have_http_status(:not_found) }
      end

      context 'when application is already scheduled' do
        before do
          application.make_scheduled!
        end

        it { is_expected.to have_http_status(:bad_request) }
      end
    end

    describe 'security' do
      before do
        allow(ClusterPatchAppWorker).to receive(:perform_async)
      end

      it_behaves_like 'a secure endpoint'
    end
  end
end
