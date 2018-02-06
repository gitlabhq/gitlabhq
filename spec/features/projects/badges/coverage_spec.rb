require 'spec_helper'

feature 'test coverage badge' do
  given!(:user) { create(:user) }
  given!(:project) { create(:project, :private) }

  context 'when user has access to view badge' do
    background do
      project.add_developer(user)
      sign_in(user)
    end

    scenario 'user requests coverage badge image for pipeline' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 100, name: 'test:1')
        create_build(pipeline, coverage: 90, name: 'test:2')
      end

      show_test_coverage_badge

      expect_coverage_badge('95.00%')
    end

    scenario 'user requests coverage badge for specific job' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: 50, name: 'test:1')
        create_build(pipeline, coverage: 50, name: 'test:2')
        create_build(pipeline, coverage: 85, name: 'coverage')
      end

      show_test_coverage_badge(job: 'coverage')

      expect_coverage_badge('85.00%')
    end

    scenario 'user requests coverage badge for pipeline without coverage' do
      create_pipeline do |pipeline|
        create_build(pipeline, coverage: nil, name: 'test')
      end

      show_test_coverage_badge

      expect_coverage_badge('unknown')
    end
  end

  context 'when user does not have access to view badge' do
    background { sign_in(user) }

    scenario 'user requests test coverage badge image' do
      show_test_coverage_badge

      expect(page).to have_gitlab_http_status(404)
    end
  end

  def create_pipeline
    opts = { project: project }

    create(:ci_pipeline, opts).tap do |pipeline|
      yield pipeline
      pipeline.update_status
    end
  end

  def create_build(pipeline, coverage:, name:)
    opts = { pipeline: pipeline, coverage: coverage, name: name }

    create(:ci_build, :success, opts)
  end

  def show_test_coverage_badge(job: nil)
    visit coverage_project_badges_path(project, ref: :master, job: job, format: :svg)
  end

  def expect_coverage_badge(coverage)
    svg = Nokogiri::XML.parse(page.body)
    expect(page.response_headers['Content-Type']).to include('image/svg+xml')
    expect(svg.at(%Q{text:contains("#{coverage}")})).to be_truthy
  end
end
