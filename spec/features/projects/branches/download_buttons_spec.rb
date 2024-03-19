# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Download buttons in branches page', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:project) { create(:project, :repository) }
  let(:download_button_selector) { '[data-testid="download-source-code-button"]' }

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit('binary-encoding').sha,
      ref: 'binary-encoding', # make sure the branch is in the 1st page!
      status: status
    )
  end

  let!(:build) do
    create(
      :ci_build,
      :success,
      :artifacts,
      pipeline: pipeline,
      status: pipeline.status,
      name: 'build'
    )
  end

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when checking branches' do
    it_behaves_like 'archive download buttons' do
      let(:ref) { 'binary-encoding' }
      let(:path_to_visit) { project_branches_filtered_path(project, state: 'all', search: ref) }
    end

    context 'with download source code button' do
      before do
        visit project_branches_filtered_path(project, state: 'all', search: 'binary-encoding')
      end

      it 'passes axe automated accessibility testing', :js do
        find_by_testid('download-source-code-button').click
        expect(page).to be_axe_clean.within(download_button_selector)
      end
    end
  end
end
