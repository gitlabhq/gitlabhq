class Spinach::Features::ProjectSnippets < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths

  step 'project "Shop" have "Snippet one" snippet' do
    create(:project_snippet,
           title: "Snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           project: project,
           author: project.users.first)
  end

  step 'project "Shop" have no "Snippet two" snippet' do
    create(:snippet,
           title: "Snippet two",
           content: "Test content",
           file_name: "snippet.rb",
           author: project.users.first)
  end

  step 'I click link "New Snippet"' do
    click_link "New Snippet"
  end

  step 'I click link "Snippet one"' do
    click_link "Snippet one"
  end

  step 'I should see "Snippet one" in snippets' do
    expect(page).to have_content "Snippet one"
  end

  step 'I should not see "Snippet two" in snippets' do
    expect(page).not_to have_content "Snippet two"
  end

  step 'I should not see "Snippet one" in snippets' do
    expect(page).not_to have_content "Snippet one"
  end

  step 'I click link "Edit"' do
    page.within ".detail-page-header" do
      click_link "Edit"
    end
  end

  step 'I click link "Delete"' do
    click_link "Delete"
  end

  step 'I submit new snippet "Snippet three"' do
    fill_in "project_snippet_title", with: "Snippet three"
    fill_in "project_snippet_file_name", with: "my_snippet.rb"
    page.within('.file-editor') do
      find(:xpath, "//input[@id='project_snippet_content']").set 'Content of snippet three'
    end
    click_button "Create snippet"
  end

  step 'I should see snippet "Snippet three"' do
    expect(page).to have_content "Snippet three"
    expect(page).to have_content "Content of snippet three"
  end

  step 'I submit new title "Snippet new title"' do
    fill_in "project_snippet_title", with: "Snippet new title"
    click_button "Save"
  end

  step 'I should see "Snippet new title"' do
    expect(page).to have_content "Snippet new title"
  end

  step 'I leave a comment like "Good snippet!"' do
    page.within('.js-main-target-form') do
      fill_in "note_note", with: "Good snippet!"
      click_button "Comment"
    end
  end

  step 'I should see comment "Good snippet!"' do
    expect(page).to have_content "Good snippet!"
  end

  step 'I visit snippet page "Snippet one"' do
    visit namespace_project_snippet_path(project.namespace, project, project_snippet)
  end

  def project_snippet
    @project_snippet ||= ProjectSnippet.find_by!(title: "Snippet one")
  end
end
