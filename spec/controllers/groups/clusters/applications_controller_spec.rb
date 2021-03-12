# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Clusters::ApplicationsController do
  include AccessMatchersForController

  def current_application
    Clusters::Cluster::APPLICATIONS[application]
  end

  shared_examples 'a secure endpoint' do
    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { subject }.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { expect { subject }.to be_denied_for(:admin) }
    it { expect { subject }.to be_allowed_for(:owner).of(group) }
    it { expect { subject }.to be_allowed_for(:maintainer).of(group) }
    it { expect { subject }.to be_denied_for(:developer).of(group) }
    it { expect { subject }.to be_denied_for(:reporter).of(group) }
    it { expect { subject }.to be_denied_for(:guest).of(group) }
    it { expect { subject }.to be_denied_for(:user) }
    it { expect { subject }.to be_denied_for(:external) }
  end

  let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
  let(:group) { cluster.group }

  describe 'POST create' do
    subject do
      post :create, params: params.merge(group_id: group)
    end

    let(:application) { 'ingress' }
    let(:params) { { application: application, id: cluster.id } }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        group.add_maintainer(user)
        sign_in(user)
      end

      it 'schedule an application installation' do
        expect(ClusterInstallAppWorker).to receive(:perform_async).with(application, anything).once

        expect { subject }.to change { current_application.count }
        expect(response).to have_gitlab_http_status(:no_content)
        expect(cluster.application_ingress).to be_scheduled
      end

      context 'when cluster do not exists' do
        before do
          cluster.destroy!
        end

        it 'return 404' do
          expect { subject }.not_to change { current_application.count }
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when application is unknown' do
        let(:application) { 'unkwnown-app' }

        it 'return 404' do
          is_expected.to have_gitlab_http_status(:not_found)
        end
      end

      context 'when application is already installing' do
        before do
          create(:clusters_applications_ingress, :installing, cluster: cluster)
        end

        it 'returns 400' do
          is_expected.to have_gitlab_http_status(:bad_request)
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
      patch :update, params: params.merge(group_id: group)
    end

    let!(:application) { create(:clusters_applications_cert_manager, :installed, cluster: cluster) }
    let(:application_name) { application.name }
    let(:params) { { application: application_name, id: cluster.id, email: "new-email@example.com" } }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        group.add_maintainer(user)
        sign_in(user)
      end

      context "when cluster and app exists" do
        it "schedules an application update" do
          expect(ClusterPatchAppWorker).to receive(:perform_async).with(application.name, anything).once

          is_expected.to have_gitlab_http_status(:no_content)

          expect(cluster.application_cert_manager).to be_scheduled
        end
      end

      context 'when cluster do not exists' do
        before do
          cluster.destroy!
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when application is unknown' do
        let(:application_name) { 'unkwnown-app' }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when application is already scheduled' do
        before do
          application.make_scheduled!
        end

        it { is_expected.to have_gitlab_http_status(:bad_request) }
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
