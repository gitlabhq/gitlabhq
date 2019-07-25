# frozen_string_literal: true

require 'spec_helper'

describe 'Download buttons in tags page' do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:tag) { 'v1.0.0' }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit(tag).sha,
           ref: tag,
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

  describe 'when checking tags' do
    context 'with artifacts' do
      before do
        visit project_tags_path(project)
      end

      it 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, "#{tag}/download", job: 'build')

        expect(page).to have_link build.name, href: href
      end
    end
  end
end
