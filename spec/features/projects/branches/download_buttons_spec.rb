# frozen_string_literal: true

require 'spec_helper'

describe 'Download buttons in branches page' do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit('binary-encoding').sha,
           ref: 'binary-encoding', # make sure the branch is in the 1st page!
           status: status)
  end

  let!(:build) do
    create(:ci_build, :success, :artifacts,
           pipeline: pipeline,
           status: pipeline.status,
           name: 'build')
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

    context 'with artifacts' do
      before do
        visit project_branches_filtered_path(project, state: 'all', search: 'binary-encoding')
      end

      it 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, 'binary-encoding/download', job: 'build')

        expect(page).to have_link build.name, href: href
      end
    end
  end
end
