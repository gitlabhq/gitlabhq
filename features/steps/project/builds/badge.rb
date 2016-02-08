class Spinach::Features::ProjectBuildsBadge < Spinach::FeatureSteps
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I display builds badge for a master branch' do
    visit badge_namespace_project_builds_path(@project.namespace, @project, ref: :master, format: :svg)
  end

  step 'I should see a build success badge' do
    expect(svg.at('text:contains("success")')).to be_truthy
  end

  step 'I should see a build failed badge' do
    expect(svg.at('text:contains("failed")')).to be_truthy
  end

  step 'build badge is a svg image' do
    expect(page.response_headers).to include('Content-Type' => 'image/svg+xml')
  end

  def svg
    Nokogiri::HTML.parse(page.body)
  end
end
