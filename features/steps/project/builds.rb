class Spinach::Features::ProjectBuilds < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers

  step 'I see summary for build' do
    expect(page).to have_content "Build ##{@build.id}"
  end

  step 'I see build trace' do
    expect(page).to have_css '#build-trace'
  end

  step 'I click artifacts download button' do
    page.within('.artifacts') { click_link 'Download' }
  end

  step 'download of build artifacts archive starts' do
    expect(page.response_headers['Content-Type']).to eq 'application/zip'
    expect(page.response_headers['Content-Transfer-Encoding']).to eq 'binary'
  end

  step 'I click artifacts browse button' do
    page.within('.artifacts') { click_link 'Browse' }
  end

  step 'I should see content of artifacts archive' do
    page.within('.tree-table') do
      expect(page).to have_no_content '..'
      expect(page).to have_content 'other_artifacts_0.1.2'
      expect(page).to have_content 'ci_artifacts.txt'
      expect(page).to have_content 'rails_sample.jpg'
    end
  end

  step 'I click link to subdirectory within build artifacts' do
    page.within('.tree-table') { click_link 'other_artifacts_0.1.2' }
  end

  step 'I should see content of subdirectory within artifacts archive' do
    page.within('.tree-table') do
      expect(page).to have_content '..'
      expect(page).to have_content 'another-subdirectory'
      expect(page).to have_content 'doc_sample.txt'
    end
  end
end
