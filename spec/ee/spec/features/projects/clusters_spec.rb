require 'spec_helper'

feature 'Clusters', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
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
  end
end
