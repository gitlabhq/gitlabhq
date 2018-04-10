require 'rails_helper'

describe 'Merge request < User sees mini pipeline graph', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, head_pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master', status: 'running', sha: project.commit.id) }
  let(:build) { create(:ci_build, pipeline: pipeline, stage: 'test', commands: 'test') }

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
    let(:artifacts_file1) { fixture_file_upload(Rails.root.join('spec/fixtures/banana_sample.gif'), 'image/gif') }
    let(:artifacts_file2) { fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'), 'image/png') }

    before do
      create(:ci_build, :success, :trace_artifact, pipeline: pipeline, legacy_artifacts_file: artifacts_file1)
      create(:ci_build, :manual, pipeline: pipeline, when: 'manual')
    end

    it 'avoids repeated database queries' do
      before = ActiveRecord::QueryRecorder.new { visit_merge_request(format: :json, serializer: 'widget') }

      create(:ci_build, :success, :trace_artifact, pipeline: pipeline, legacy_artifacts_file: artifacts_file2)
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

    it 'expands when hovered' do
      find('.mini-pipeline-graph-dropdown-toggle')
      before_width = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').outerWidth();")

      toggle.hover

      find('.mini-pipeline-graph-dropdown-toggle')
      after_width = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').outerWidth();")

      expect(before_width).to be < after_width
    end

    it 'shows dropdown caret when hovered' do
      toggle.hover

      expect(toggle).to have_selector('.fa-caret-down')
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
