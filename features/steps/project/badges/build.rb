class Spinach::Features::ProjectBadgesBuild < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I display builds badge for a master branch' do
    visit build_namespace_project_badges_path(@project.namespace, @project, ref: :master, format: :svg)
  end

  step 'I should see a build success badge' do
    expect_badge('success')
  end

  step 'I should see a build failed badge' do
    expect_badge('failed')
  end

  step 'I should see a build running badge' do
    expect_badge('running')
  end

  step 'I should see a badge that has not been cached' do
    expect(page.response_headers).to include('Cache-Control' => 'no-cache')
  end

  def expect_badge(status)
    svg = Nokogiri::XML.parse(page.body)
    expect(page.response_headers).to include('Content-Type' => 'image/svg+xml')
    expect(svg.at(%Q{text:contains("#{status}")})).to be_truthy
  end
end
