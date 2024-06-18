# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees pipelines from forked project', :js,
  feature_category: :continuous_integration do
  include ProjectForksHelper

  let(:target_project) { create(:project, :public, :repository) }
  let(:user) { target_project.creator }
  let(:forked_project) { fork_project(target_project, nil, repository: true) }
  let!(:merge_request) do
    create(
      :merge_request_with_diffs,
      source_project: forked_project,
      target_project: target_project,
      description: 'Test merge request'
    )
  end

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: forked_project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch
    )
  end

  before do
    create(:ci_build, pipeline: pipeline, name: 'rspec')
    create(:ci_build, pipeline: pipeline, name: 'spinach')
    sign_in(user)
  end

  context 'with feature flag `mr_pipelines_graphql` turned off' do
    before do
      stub_feature_flags(mr_pipelines_graphql: false)
      visit project_merge_request_path(target_project, merge_request)
    end

    it 'user visits a pipelines page', :sidekiq_might_not_need_inline do
      page.within('.merge-request-tabs') { click_link 'Pipelines' }

      page.within('.ci-table') do
        expect(page).to have_content(pipeline.id)
      end
    end
  end

  context 'with feature flag `mr_pipelines_graphql` turned on' do
    before do
      stub_feature_flags(mr_pipelines_graphql: true)
      visit project_merge_request_path(target_project, merge_request)
    end

    it 'user visits a pipelines page',
      :sidekiq_might_not_need_inline,
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/467299' do
      page.within('.merge-request-tabs') { click_link 'Pipelines' }

      expect(page).to have_content(pipeline.id)
    end
  end
end
