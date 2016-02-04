class Spinach::Features::ProjectBuildsSummary < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I see button to CI Lint' do
    page.within('.nav-controls') do
      ci_lint_tool_link = page.find_link('CI Lint')
      expect(ci_lint_tool_link[:href]).to eq ci_lint_path
    end
  end
end
