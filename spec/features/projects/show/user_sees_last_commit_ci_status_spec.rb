# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees last commit CI status', feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :repository, :public) }

  it 'shows the project README', :js do
    project.enable_ci
    pipeline = create(:ci_pipeline, project: project, sha: project.commit.sha, ref: 'master')
    pipeline.skip

    visit project_path(project)

    page.within '.commit-detail' do
      expect(page).to have_content(project.commit.sha[0..6])
      expect(page).to have_selector('[aria-label="Pipeline: Skipped"]')
    end
  end
end
