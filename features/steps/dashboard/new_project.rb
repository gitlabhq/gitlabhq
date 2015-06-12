class Spinach::Features::NewProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click "New project" link' do
    page.within('.content') do
      click_link "New project"
    end
  end

  step 'I see "New project" page' do
    expect(page).to have_content("Project path")
  end

  step 'I click on "Import project from GitHub"' do
    first('.how_to_import_link').click
  end

  step 'I see instructions on how to import from GitHub' do
    github_modal = first('.modal-body')
    expect(github_modal).to be_visible
    expect(github_modal).to have_content "To enable importing projects from GitHub"

    page.all('.modal-body').each do |element|
      expect(element).not_to be_visible unless element == github_modal
    end
  end
end
