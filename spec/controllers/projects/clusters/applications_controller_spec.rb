# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Clusters::ApplicationsController do
  include AccessMatchersForController

  def current_application
    Clusters::Cluster::APPLICATIONS[application]
  end

  shared_examples 'a secure endpoint' do
    it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
      expect { subject }.to be_allowed_for(:admin)
    end
    it 'is denied for admin when admin mode disabled' do
      expect { subject }.to be_denied_for(:admin)
    end
    it { expect { subject }.to be_allowed_for(:owner).of(project) }
    it { expect { subject }.to be_allowed_for(:maintainer).of(project) }
    it { expect { subject }.to be_denied_for(:developer).of(project) }
    it { expect { subject }.to be_denied_for(:reporter).of(project) }
    it { expect { subject }.to be_denied_for(:guest).of(project) }
    it { expect { subject }.to be_denied_for(:user) }
    it { expect { subject }.to be_denied_for(:external) }
  end

  describe 'POST create' do
    subject do
      post :create, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }
    let(:application) { 'helm' }
    let(:params) { { application: application, id: cluster.id } }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'schedule an application installation' do
        expect(ClusterInstallAppWorker).to receive(:perform_async).with(application, anything).once

        expect { subject }.to change { current_application.count }
        expect(response).to have_gitlab_http_status(:no_content)
        expect(cluster.application_helm).to be_scheduled
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
          create(:clusters_applications_helm, :installing, cluster: cluster)
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
      patch :update, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }
    let!(:application) { create(:clusters_applications_knative, :installed, cluster: cluster) }
    let(:application_name) { application.name }
    let(:params) { { application: application_name, id: cluster.id, hostname: "new.example.com" } }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context "when cluster and app exists" do
        it "schedules an application update" do
          expect(ClusterPatchAppWorker).to receive(:perform_async).with(application.name, anything).once

          is_expected.to have_gitlab_http_status(:no_content)

          expect(cluster.application_knative).to be_scheduled
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

  describe 'DELETE destroy' do
    subject do
      delete :destroy, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }
    let!(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
    let(:application_name) { application.name }
    let(:params) { { application: application_name, id: cluster.id } }
    let(:worker_class) { Clusters::Applications::UninstallWorker }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context "when cluster and app exists" do
        it "schedules an application update" do
          expect(worker_class).to receive(:perform_async).with(application.name, application.id).once

          is_expected.to have_gitlab_http_status(:no_content)

          expect(cluster.application_prometheus).to be_scheduled
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
        allow(worker_class).to receive(:perform_async)
      end

      it_behaves_like 'a secure endpoint'
    end
  end
end
