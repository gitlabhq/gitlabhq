require 'spec_helper'

feature 'EE Clusters' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user has a cluster' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

    context 'when license has multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
      end

      context 'when user visits clusters page' do
        before do
          visit project_clusters_path(project)
        end

        it 'user sees a add cluster button ' do
          expect(page).not_to have_selector('.js-add-cluster.disabled')
          expect(page).to have_selector('.js-add-cluster')
        end
      end
    end

    context 'when license does not have multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
      end

      context 'when user visits cluster index page' do
        before do
          visit project_clusters_path(project)
        end

        it 'user sees a disabled add cluster button ' do
          expect(page).to have_selector('.js-add-cluster.disabled')
        end
      end
    end
  end
end
