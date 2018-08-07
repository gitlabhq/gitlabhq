# frozen_string_literal: true
require 'spec_helper'

describe Admin::GeoProjectsController, :geo do
  set(:admin) { create(:admin) }
  let(:synced_registry) { create(:geo_project_registry, :synced) }

  before do
    sign_in(admin)
  end

  shared_examples 'license required' do
    context 'without a valid license' do
      it 'redirects to license page with a flash message' do
        expect(subject).to redirect_to(admin_license_path)
        expect(flash[:alert]).to include('You need a different license to use Geo replication')
      end
    end
  end

  describe '#index' do
    subject { get :index }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'renders synced template when no extra get params is specified' do
        expect(subject).to have_gitlab_http_status(200)
        expect(subject).to render_template(:index, partial: :synced)
      end

      context 'with sync_status=pending' do
        subject { get :index, sync_status: 'pending' }

        it 'renders pending template' do
          expect(subject).to have_gitlab_http_status(200)
          expect(subject).to render_template(:index, partial: :pending)
        end
      end

      context 'with sync_status=failed' do
        subject { get :index, sync_status: 'failed' }

        it 'renders failed template' do
          expect(subject).to have_gitlab_http_status(200)
          expect(subject).to render_template(:index, partial: :failed)
        end
      end

      context 'with sync_status=never' do
        subject { get :index, sync_status: 'never' }

        it 'renders failed template' do
          expect(subject).to have_gitlab_http_status(200)
          expect(subject).to render_template(:index, partial: :never)
        end
      end
    end
  end

  describe '#recheck' do
    subject { post :recheck, id: synced_registry }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'flags registry for recheck' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:notice]).to include('is scheduled for re-check')
        expect(synced_registry.reload.verification_pending?).to be_truthy
      end
    end
  end

  describe '#resync' do
    subject { post :resync, id: synced_registry }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'flags registry for resync' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:notice]).to include('is scheduled for re-sync')
        expect(synced_registry.reload.resync_repository?).to be_truthy
      end
    end
  end

  describe '#force_redownload' do
    subject { post :force_redownload, id: synced_registry }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'flags registry for re-download' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:notice]).to include('is scheduled for forced re-download')
        expect(synced_registry.reload.should_be_redownloaded?('repository')).to be_truthy
      end
    end
  end
end
