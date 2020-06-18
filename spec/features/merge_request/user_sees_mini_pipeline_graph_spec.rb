# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request < User sees mini pipeline graph', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, head_pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master', status: 'running', sha: project.commit.id) }
  let(:build) { create(:ci_build, pipeline: pipeline, stage: 'test') }

  before do
    build.run
    build.trace.set('hello')
    sign_in(user)
    visit_merge_request
  end

  def visit_merge_request(format: :html, serializer: nil)
    visit project_merge_request_path(project, merge_request, format: format, serializer: serializer)
  end

  it 'displays a mini pipeline graph' do
    expect(page).to have_selector('.mr-widget-pipeline-graph')
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

  describe 'build list toggle' do
    let(:toggle) do
      find('.mini-pipeline-graph-dropdown-toggle')
      first('.mini-pipeline-graph-dropdown-toggle')
    end

    # Status icon button styles should update as described in
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/42769
    it 'has unique styles for default, :hover, :active, and :focus states' do
      find('.mini-pipeline-graph-dropdown-toggle')
      default_background_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('background-color');")
      default_foreground_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible svg').css('fill');")
      default_box_shadow = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('box-shadow');")

      toggle.hover

      find('.mini-pipeline-graph-dropdown-toggle')
      hover_background_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('background-color');")
      hover_foreground_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible svg').css('fill');")
      hover_box_shadow = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('box-shadow');")

      page.driver.browser.action.click_and_hold(toggle.native).perform

      find('.mini-pipeline-graph-dropdown-toggle')
      active_background_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('background-color');")
      active_foreground_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible svg').css('fill');")
      active_box_shadow = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('box-shadow');")

      page.driver.browser.action.release(toggle.native)
                                .move_by(100, 100)
                                .perform

      find('.mini-pipeline-graph-dropdown-toggle')
      focus_background_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('background-color');")
      focus_foreground_color = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible svg').css('fill');")
      focus_box_shadow = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').css('box-shadow');")

      expect(default_background_color).not_to eq(hover_background_color)
      expect(hover_background_color).not_to eq(active_background_color)
      expect(default_background_color).not_to eq(active_background_color)

      expect(default_foreground_color).not_to eq(hover_foreground_color)
      expect(hover_foreground_color).not_to eq(active_foreground_color)
      expect(default_foreground_color).not_to eq(active_foreground_color)

      expect(focus_background_color).to eq(hover_background_color)
      expect(focus_foreground_color).to eq(hover_foreground_color)

      expect(default_box_shadow).to eq('none')
      expect(hover_box_shadow).to eq('none')
      expect(active_box_shadow).not_to eq('none')
      expect(focus_box_shadow).not_to eq('none')
    end

    it 'shows tooltip when hovered' do
      toggle.hover

      expect(page).to have_selector('.tooltip')
    end
  end

  describe 'builds list menu' do
    let(:toggle) do
      find('.mini-pipeline-graph-dropdown-toggle')
      first('.mini-pipeline-graph-dropdown-toggle')
    end

    before do
      toggle.click
      wait_for_requests
    end

    it 'pens when toggle is clicked' do
      expect(toggle.find(:xpath, '..')).to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    it 'closes when toggle is clicked again' do
      toggle.click

      expect(toggle.find(:xpath, '..')).not_to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    it 'closes when clicking somewhere else' do
      find('body').click

      expect(toggle.find(:xpath, '..')).not_to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    describe 'build list build item' do
      let(:build_item) do
        find('.mini-pipeline-graph-dropdown-item')
        first('.mini-pipeline-graph-dropdown-item')
      end

      it 'visits the build page when clicked' do
        build_item.click
        find('.build-page')

        expect(current_path).to eql(project_job_path(project, build))
      end

      it 'shows tooltip when hovered' do
        build_item.hover

        expect(page).to have_selector('.tooltip')
      end
    end
  end
end
