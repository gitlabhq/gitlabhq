class Spinach::Features::ProjectBuildsArtifacts < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include RepoHelpers
  include WaitForAjax

  step 'I click artifacts download button' do
    click_link 'Download'
  end

  step 'I click artifacts browse button' do
    click_link 'Browse'
    expect(page).not_to have_selector('.build-sidebar')
  end

  step 'I should see content of artifacts archive' do
    page.within('.tree-table') do
      expect(page).to have_no_content '..'
      expect(page).to have_content 'other_artifacts_0.1.2'
      expect(page).to have_content 'ci_artifacts.txt'
      expect(page).to have_content 'rails_sample.jpg'
    end
  end

  step 'I should see the build header' do
    page.within('.build-header') do
      expect(page).to have_content "Job ##{@build.id} in pipeline ##{@pipeline.id} for commit #{@pipeline.short_sha}"
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

  step 'I should see the directory name in the breadcrumb' do
    page.within('.repo-breadcrumb') do
      expect(page).to have_content 'other_artifacts_0.1.2'
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

  step 'I click a link to file within build artifacts' do
    page.within('.tree-table') { find_link('ci_artifacts.txt').click }
    wait_for_ajax
  end

  step 'I see a download link' do
    expect(page).to have_link 'download it'
  end

  step 'I click a first row within build artifacts table' do
    row = first('tr[data-link]')
    @row_path = row['data-link']
    row.click
  end

  step 'page with a coresponding path is loading' do
    expect(current_path).to eq @row_path
  end
end
