# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request < User sees pipeline mini graph', :js, feature_category: :continuous_integration do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, head_pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master', status: 'running', sha: project.commit.id) }
  let(:build) { create(:ci_build, pipeline: pipeline, stage: 'test') }

  dropdown_selector = '[data-testid="pipeline-mini-graph-dropdown"]'

  before do
    build.run
    build.trace.set('hello')
    sign_in(user)
    visit_merge_request
  end

  def visit_merge_request(format: :html, serializer: nil)
    visit project_merge_request_path(project, merge_request, format: format, serializer: serializer)
  end

  it 'displays a pipeline mini graph' do
    expect(page).to have_selector('[data-testid="pipeline-mini-graph"]')
  end

  context 'as json' do
    let(:artifacts_file1) { fixture_file_upload(File.join('spec/fixtures/banana_sample.gif'), 'image/gif') }
    let(:artifacts_file2) { fixture_file_upload(File.join('spec/fixtures/dk.png'), 'image/png') }

    before do
      job = create(:ci_build, :success, :trace_artifact, pipeline: pipeline)
      create(:ci_job_artifact, :archive, file: artifacts_file1, job: job)
      create(:ci_build, :manual, pipeline: pipeline, when: 'manual')
    end

    # TODO: https://gitlab.com/gitlab-org/gitlab-foss/issues/48034
    xit 'avoids repeated database queries' do
      before = ActiveRecord::QueryRecorder.new { visit_merge_request(format: :json, serializer: 'widget') }

      job = create(:ci_build, :success, :trace_artifact, pipeline: pipeline)
      create(:ci_job_artifact, :archive, file: artifacts_file2, job: job)
      create(:ci_build, :manual, pipeline: pipeline, when: 'manual')

      after = ActiveRecord::QueryRecorder.new { visit_merge_request(format: :json, serializer: 'widget') }

      expect(before.count).to eq(after.count)
      expect(before.cached_count).to eq(after.cached_count)
    end
  end

  describe 'stage dropdown toggle' do
    let(:toggle) do
      find(dropdown_selector)
      first(dropdown_selector)
    end

    before do
      wait_for_requests
    end

    it 'shows tooltip when hovered' do
      toggle.hover

      expect(page).to have_selector('.tooltip')
    end
  end

  describe 'stage dropdown' do
    let(:toggle) do
      find(dropdown_selector)
      first(dropdown_selector)
    end

    before do
      toggle.click
      wait_for_requests
    end

    it 'pens when toggle is clicked' do
      expect(toggle.find(:xpath, '..')).to have_selector('[data-testid="pipeline-mini-graph-dropdown-menu-list"]')
    end

    it 'closes when toggle is clicked again' do
      toggle.click

      expect(toggle.find(:xpath, '..')).not_to have_selector('[data-testid="pipeline-mini-graph-dropdown-menu-list"]')
    end

    it 'closes when clicking somewhere else' do
      find('body').click

      expect(toggle.find(:xpath, '..')).not_to have_selector('[data-testid="pipeline-mini-graph-dropdown-menu"]')
    end

    describe 'job list job item' do
      let(:job_item) do
        first('[data-testid="job-name"]')
      end

      it 'visits the job page when clicked' do
        job_item.click
        find('.build-page')

        expect(page).to have_current_path(project_job_path(project, build), ignore_query: true)
      end

      it 'shows tooltip when hovered' do
        job_item.hover

        expect(page).to have_selector('.tooltip')
      end
    end
  end
end
