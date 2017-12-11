require 'spec_helper'

feature 'Clusters', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user does not have a cluster and visits cluster index page' do
    before do
      visit project_clusters_path(project)
    end

    it 'sees empty state' do
      expect(page).to have_link('Add cluster')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
    end

    it 'user sees a table with one cluster' do
      # One is the header row, the other the cluster row
      expect(page).to have_selector('.gl-responsive-table-row', count: 2)
    end
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
    end

    it 'user sees a table with one cluster' do
      # One is the header row, the other the cluster row
      expect(page).to have_selector('.gl-responsive-table-row', count: 2)
    end

    it 'user sees navigation tabs' do
      expect(page.find('.js-active-tab').text).to include('Active')
      expect(page.find('.js-active-tab .badge').text).to include('1')

      expect(page.find('.js-inactive-tab').text).to include('Inactive')
      expect(page.find('.js-inactive-tab .badge').text).to include('0')

      expect(page.find('.js-all-tab').text).to include('All')
      expect(page.find('.js-all-tab .badge').text).to include('1')
    end

    context 'inline update of cluster' do
      it 'user can update cluster' do
        expect(page).to have_selector('.js-toggle-cluster-list')
      end

      context 'with sucessfull request' do
        it 'user sees updated cluster' do
          expect do
            page.find('.js-toggle-cluster-list').click
            wait_for_requests
          end.to change { cluster.reload.enabled }

          expect(page).not_to have_selector('.is-checked')
          expect(cluster.reload).not_to be_enabled
        end
      end

      context 'with failed request' do
        it 'user sees not update cluster and error message' do
          expect_any_instance_of(Clusters::UpdateService).to receive(:execute).and_call_original
          allow_any_instance_of(Clusters::Cluster).to receive(:valid?) { false }

          page.find('.js-toggle-cluster-list').click

          expect(page).to have_content('Something went wrong on our end.')
          expect(page).to have_selector('.is-checked')
          expect(cluster.reload).to be_enabled
        end
      end
    end

    context 'when user clicks on a cluster' do
      before do
        click_link cluster.name
      end

    context 'when license has multiple clusters feature' do
      before do
        allow_any_instance_of(EE::Project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
      end

      it 'user sees a add cluster button ' do
        expect(page).to have_selector('.js-add-cluster')
      end
    end

    context 'when license does not have multiple clusters feature' do
      before do
        allow_any_instance_of(EE::Project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
      end

      it 'user sees a disabled add cluster button ' do
        expect(page).to have_selector('.js-add-cluster.disabled')
      end
    end

    it 'user sees navigation tabs' do
      expect(page.find('.js-active-tab').text).to include('Active')
      expect(page.find('.js-active-tab .badge').text).to include('1')

      expect(page.find('.js-inactive-tab').text).to include('Inactive')
      expect(page.find('.js-inactive-tab .badge').text).to include('0')

      expect(page.find('.js-all-tab').text).to include('All')
      expect(page.find('.js-all-tab .badge').text).to include('1')
    end

    context 'inline update of cluster' do
      it 'user can update cluster' do
        expect(page).to have_selector('.js-toggle-cluster-list')
      end

      context 'with sucessfull request' do
        it 'user sees updated cluster' do
          expect do
            page.find('.js-toggle-cluster-list').click
            wait_for_requests
          end.to change { cluster.reload.enabled }

          expect(page).not_to have_selector('.is-checked')
          expect(cluster.reload).not_to be_enabled
        end
      end

      context 'with failed request' do
        it 'user sees not update cluster and error message' do
          expect_any_instance_of(Clusters::UpdateService).to receive(:execute).and_call_original
          allow_any_instance_of(Clusters::Cluster).to receive(:valid?) { false }

          page.find('.js-toggle-cluster-list').click

          expect(page).to have_content('Something went wrong on our end.')
          expect(page).to have_selector('.is-checked')
          expect(cluster.reload).to be_enabled
        end
      end
    end

    context 'when user clicks on a cluster' do
      before do
        click_link cluster.name
      end

      it 'user sees a cluster details page' do
        expect(page).to have_button('Save')
        expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
      end
    end
  end
end
