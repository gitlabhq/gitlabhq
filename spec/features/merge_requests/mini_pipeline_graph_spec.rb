require 'rails_helper'

feature 'Mini Pipeline Graph', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, source_project: project, head_pipeline: pipeline) }

  let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master', status: 'running', sha: project.commit.id) }
  let(:build) { create(:ci_build, pipeline: pipeline, stage: 'test', commands: 'test') }

  before do
    build.run

    sign_in(user)
    visit_merge_request
  end

  def visit_merge_request(format = :html)
    visit project_merge_request_path(project, merge_request, format: format)
  end

  it 'should display a mini pipeline graph' do
    expect(page).to have_selector('.mr-widget-pipeline-graph')
  end

  context 'as json' do
    let(:artifacts_file1) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
    let(:artifacts_file2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png') }

    before do
      create(:ci_build, pipeline: pipeline, artifacts_file: artifacts_file1)
      create(:ci_build, pipeline: pipeline, when: 'manual')
    end

    it 'avoids repeated database queries' do
      before = ActiveRecord::QueryRecorder.new { visit_merge_request(:json) }

      create(:ci_build, pipeline: pipeline, artifacts_file: artifacts_file2)
      create(:ci_build, pipeline: pipeline, when: 'manual')

      after = ActiveRecord::QueryRecorder.new { visit_merge_request(:json) }

      expect(before.count).to eq(after.count)
      expect(before.cached_count).to eq(after.cached_count)
    end
  end

  describe 'build list toggle' do
    let(:toggle) do
      find('.mini-pipeline-graph-dropdown-toggle')
      first('.mini-pipeline-graph-dropdown-toggle')
    end

    it 'should expand when hovered' do
      before_width = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').outerWidth();")

      toggle.hover

      after_width = evaluate_script("$('.mini-pipeline-graph-dropdown-toggle:visible').outerWidth();")

      expect(before_width).to be < after_width
    end

    it 'should show dropdown caret when hovered' do
      toggle.hover

      expect(toggle).to have_selector('.fa-caret-down')
    end

    it 'should show tooltip when hovered' do
      toggle.hover

      expect(toggle.find(:xpath, '..')).to have_selector('.tooltip')
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

    it 'should open when toggle is clicked' do
      expect(toggle.find(:xpath, '..')).to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    it 'should close when toggle is clicked again' do
      toggle.trigger('click')

      expect(toggle.find(:xpath, '..')).not_to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    it 'should close when clicking somewhere else' do
      find('body').click

      expect(toggle.find(:xpath, '..')).not_to have_selector('.mini-pipeline-graph-dropdown-menu')
    end

    describe 'build list build item' do
      let(:build_item) do
        find('.mini-pipeline-graph-dropdown-item')
        first('.mini-pipeline-graph-dropdown-item')
      end

      it 'should visit the build page when clicked' do
        build_item.click
        find('.build-page')

        expect(current_path).to eql(project_job_path(project, build))
      end

      it 'should show tooltip when hovered' do
        build_item.hover

        expect(build_item.find(:xpath, '..')).to have_selector('.tooltip')
      end
    end
  end
end
