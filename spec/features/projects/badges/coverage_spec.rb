# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'test coverage badge', feature_category: :code_testing do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :private) }

  context 'when user has access to view badge' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'user requests coverage badge image for pipeline with custom limits - 80% good' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 80, name: 'test:1')
      end

      show_test_coverage_badge(min_good: 75, min_acceptable: 50, min_medium: 25)

      expect_coverage_badge_color(:good)
      expect_coverage_badge('80.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 74% - bad config' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 74, name: 'test:1')
      end
      # User sets a minimum good value that is lower than min acceptable and min medium,
      # in which case we force the min acceptable value to be min good -1 and min medium value to be min acceptable -1
      show_test_coverage_badge(min_good: 75, min_acceptable: 76, min_medium: 77)

      expect_coverage_badge_color(:acceptable)
      expect_coverage_badge('74.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 73% - bad config' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 73, name: 'test:1')
      end
      # User sets a minimum good value that is lower than min acceptable and min medium,
      # in which case we force the min acceptable value to be min good -1 and min medium value to be min acceptable -1
      show_test_coverage_badge(min_good: 75, min_acceptable: 76, min_medium: 77)

      expect_coverage_badge_color(:medium)
      expect_coverage_badge('73.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 72% - partial config - low' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 72, name: 'test:1')
      end
      # User only sets good to 75 and leaves the others on the default settings,
      # in which case we force the min acceptable value to be min good -1 and min medium value to be min acceptable -1
      show_test_coverage_badge(min_good: 75)

      expect_coverage_badge_color(:low)
      expect_coverage_badge('72.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 72% - partial config - medium' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 72, name: 'test:1')
      end
      # User only sets good to 74 and leaves the others on the default settings,
      # in which case we force the min acceptable value to be min good -1 and min medium value to be min acceptable -1
      show_test_coverage_badge(min_good: 74)

      expect_coverage_badge_color(:medium)
      expect_coverage_badge('72.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 72% - partial config - medium v2' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 72, name: 'test:1')
      end
      # User only sets medium to 72 and leaves the others on the defaults good as 95 and acceptable as 90
      show_test_coverage_badge(min_medium: 72)

      expect_coverage_badge_color(:medium)
      expect_coverage_badge('72.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 70% acceptable' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 70, name: 'test:1')
      end

      show_test_coverage_badge(min_good: 75, min_acceptable: 50, min_medium: 25)

      expect_coverage_badge_color(:acceptable)
      expect_coverage_badge('70.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 30% medium' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 30, name: 'test:1')
      end

      show_test_coverage_badge(min_good: 75, min_acceptable: 50, min_medium: 25)

      expect_coverage_badge_color(:medium)
      expect_coverage_badge('30.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - 20% low' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 20, name: 'test:1')
      end

      show_test_coverage_badge(min_good: 75, min_acceptable: 50, min_medium: 25)

      expect_coverage_badge_color(:low)
      expect_coverage_badge('20.00%')
    end

    it 'user requests coverage badge image for pipeline with custom limits - nonsense values which use the defaults' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 92, name: 'test:1')
      end

      show_test_coverage_badge(min_good: "nonsense", min_acceptable: "rubbish", min_medium: "NaN")

      expect_coverage_badge_color(:acceptable)
      expect_coverage_badge('92.00%')
    end

    it 'user requests coverage badge image for pipeline' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 100, name: 'test:1')
        create_build(pipeline, coverage: 90, name: 'test:2')
      end

      show_test_coverage_badge

      expect_coverage_badge_color(:good)
      expect_coverage_badge('95.00%')
    end

    it 'user requests coverage badge for specific job' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 50, name: 'test:1')
        create_build(pipeline, coverage: 50, name: 'test:2')
        create_build(pipeline, coverage: 85, name: 'coverage')
      end

      show_test_coverage_badge(job: 'coverage')

      expect_coverage_badge_color(:medium)
      expect_coverage_badge('85.00%')
    end

    it 'user requests coverage badge for pipeline without coverage' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: nil, name: 'test')
      end

      show_test_coverage_badge

      expect_coverage_badge('unknown')
    end
  end

  context 'when user does not have access to view badge' do
    before do
      sign_in(user)
    end

    it 'user requests test coverage badge image' do
      show_test_coverage_badge

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  def create_pipeline
    opts = { project: project }

    create(:ci_pipeline, opts).tap do |pipeline|
      yield pipeline
      ::Ci::ProcessPipelineService.new(pipeline).execute
    end
  end

  def create_build(pipeline, coverage:, name:)
    opts = { pipeline: pipeline, coverage: coverage, name: name }

    create(:ci_build, :success, opts)
  end

  def show_test_coverage_badge(job: nil, min_good: nil, min_acceptable: nil, min_medium: nil)
    visit coverage_project_badges_path(
      project,
      ref: :master,
      job: job,
      min_good: min_good,
      min_acceptable: min_acceptable,
      min_medium: min_medium,
      format: :svg
    )
  end

  def expect_coverage_badge(coverage)
    svg = Nokogiri::XML.parse(page.body)
    expect(page.response_headers['Content-Type']).to include('image/svg+xml')
    expect(svg.at(%{text:contains("#{coverage}")})).to be_truthy
  end

  def expect_coverage_badge_color(color)
    svg = Nokogiri::HTML(page.body)
    expect(page.response_headers['Content-Type']).to include('image/svg+xml')
    badge_color = svg.xpath("//path[starts-with(@d, 'M62')]")[0].attributes['fill'].to_s
    expected_badge_color = Gitlab::Ci::Badge::Coverage::Template::STATUS_COLOR[color]
    expect(badge_color).to eq(expected_badge_color)
  end
end
