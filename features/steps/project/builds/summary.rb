class Spinach::Features::ProjectBuildsSummary < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I see coverage' do
    page.within('td.coverage') do
      expect(page).to have_content "99.9%"
    end
  end

  step 'I see button to CI Lint' do
    page.within('.nav-controls') do
      ci_lint_tool_link = page.find_link('CI Lint')
      expect(ci_lint_tool_link[:href]).to eq ci_lint_path
    end
  end

  step 'I click erase build button' do
    click_link 'Erase'
  end

  step 'recent build has been erased' do
    expect(@build.artifacts_file.exists?).to be_falsy
    expect(@build.artifacts_metadata.exists?).to be_falsy
    expect(@build.trace).to be_empty
  end

  step 'recent build summary does not have artifacts widget' do
    expect(page).to have_no_css('.artifacts')
  end

  step 'recent build summary contains information saying that build has been erased' do
    page.within('.erased') do
      expect(page).to have_content 'Build has been erased'
    end
  end
end
