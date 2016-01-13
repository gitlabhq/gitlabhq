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

  step 'recent build artifacts contain directory with UTF-8 characters' do
    # metadata fixture contains relevant directory
  end

  step 'I navigate to directory with UTF-8 characters in name' do
    page.within('.tree-table') { click_link 'tests_encoding' }
    page.within('.tree-table') { click_link 'utf8 test dir ✓' }
  end

  step 'I should see content of directory with UTF-8 characters in name' do
    page.within('.tree-table') do
      expect(page).to have_content '..'
      expect(page).to have_content 'regular_file_2'
    end
  end

  step 'recent build artifacts contain directory with invalid UTF-8 characters' do
    # metadata fixture contains relevant directory
  end

  step 'I navigate to parent directory of directory with invalid name' do
    page.within('.tree-table') { click_link 'tests_encoding' }
  end

  step 'I should not see directory with invalid name on the list' do
    page.within('.tree-table') do
      expect(page).to have_no_content('non-utf8-dir')
    end
  end

  step 'I click download button for a file within build artifacts' do
    page.within('.tree-table') { first('.artifact-download').click }
  end

  step 'download of a file extracted from build artifacts should start' do
    # this will be accelerated by Workhorse
    response_json = JSON.parse(page.body, symbolize_names: true)
    expect(response_json[:archive]).to end_with('build_artifacts.zip')
    expect(response_json[:entry]).to eq Base64.encode64('ci_artifacts.txt')
  end
end
