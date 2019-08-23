# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Show > User sees last commit CI status' do
  set(:project) { create(:project, :repository, :public) }

  before do
    stub_feature_flags(vue_file_list: false)
  end

  it 'shows the project README', :js do
    project.enable_ci
    pipeline = create(:ci_pipeline, project: project, sha: project.commit.sha, ref: 'master')
    pipeline.skip

    visit project_path(project)

    page.within '.blob-commit-info' do
      expect(page).to have_content(project.commit.sha[0..6])
      expect(page).to have_link('Pipeline: skipped')
    end
  end
end
