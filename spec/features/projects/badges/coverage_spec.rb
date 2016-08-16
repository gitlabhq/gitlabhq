require 'spec_helper'

feature 'test coverage badge' do
  given!(:user) { create(:user) }
  given!(:project) { create(:project, :private) }

  given!(:pipeline) do
    create(:ci_pipeline, project: project,
                         ref: 'master',
                         sha: project.commit.id)
  end

  context 'when user has access to view badge' do
    background do
      project.team << [user, :developer]
      login_as(user)
    end

    scenario 'user requests coverage badge image for pipeline' do
      create_job(coverage: 100, name: 'test:1')
      create_job(coverage: 90, name: 'test:2')

      show_test_coverage_badge

      expect_coverage_badge('95%')
    end

    scenario 'user requests coverage badge for specific job' do
      create_job(coverage: 50, name: 'test:1')
      create_job(coverage: 50, name: 'test:2')
      create_job(coverage: 85, name: 'coverage')

      show_test_coverage_badge(job: 'coverage')

      expect_coverage_badge('85%')
    end

    scenario 'user requests coverage badge for pipeline without coverage' do
      create_job(coverage: nil, name: 'test')

      show_test_coverage_badge

      expect_coverage_badge('unknown')
    end
  end

  context 'when user does not have access to view badge' do
    background { login_as(user) }

    scenario 'user requests test coverage badge image' do
      show_test_coverage_badge

      expect(page).to have_http_status(404)
    end
  end

  def create_job(coverage:, name:)
    create(:ci_build, name: name,
                      coverage: coverage,
                      pipeline: pipeline)
  end

  def show_test_coverage_badge(job: nil)
    visit coverage_namespace_project_badges_path(
      project.namespace, project, ref: :master, job: job, format: :svg)
  end

  def expect_coverage_badge(coverage)
    svg = Nokogiri::XML.parse(page.body)
    expect(page.response_headers['Content-Type']).to include('image/svg+xml')
    expect(svg.at(%Q{text:contains("#{coverage}")})).to be_truthy
  end
end
