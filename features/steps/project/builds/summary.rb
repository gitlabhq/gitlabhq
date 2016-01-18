class Spinach::Features::ProjectBuildsSummary < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I see details of a build' do
    expect(page).to have_content "Build ##{@build.id}"
  end

  step 'I see build trace' do
    expect(page).to have_css '#build-trace'
  end

  step 'I see button to CI Lint' do
    page.within('.controls') do
      ci_lint_tool_link = page.find_link('CI Lint')
      expect(ci_lint_tool_link[:href]).to eq ci_lint_path
    end
  end
end
