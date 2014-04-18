class ProjectSnippets < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths

  And 'project "Shop" have "Snippet one" snippet' do
    create(:project_snippet,
           title: "Snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           project: project,
           author: project.users.first)
  end

  And 'project "Shop" have no "Snippet two" snippet' do
    create(:snippet,
           title: "Snippet two",
           content: "Test content",
           file_name: "snippet.rb",
           author: project.users.first)
  end

  Given 'I click link "New Snippet"' do
    click_link "Add new snippet"
  end

  Given 'I click link "Snippet one"' do
    click_link "Snippet one"
  end

  Then 'I should see "Snippet one" in snippets' do
    page.should have_content "Snippet one"
  end

  And 'I should not see "Snippet two" in snippets' do
    page.should_not have_content "Snippet two"
  end

  And 'I should not see "Snippet one" in snippets' do
    page.should_not have_content "Snippet one"
  end

  And 'I click link "Edit"' do
    within ".file-title" do
      click_link "Edit"
    end
  end

  And 'I click link "Remove Snippet"' do
    click_link "Remove snippet"
  end

  And 'I submit new snippet "Snippet three"' do
    fill_in "project_snippet_title", :with => "Snippet three"
    fill_in "project_snippet_file_name", :with => "my_snippet.rb"
    within('.file-editor') do
      find(:xpath, "//input[@id='project_snippet_content']").set 'Content of snippet three'
    end
    click_button "Create snippet"
  end

  Then 'I should see snippet "Snippet three"' do
    page.should have_content "Snippet three"
    page.should have_content "Content of snippet three"
  end

  And 'I submit new title "Snippet new title"' do
    fill_in "project_snippet_title", :with => "Snippet new title"
    click_button "Save"
  end

  Then 'I should see "Snippet new title"' do
    page.should have_content "Snippet new title"
  end

  And 'I leave a comment like "Good snippet!"' do
    within('.js-main-target-form') do
      fill_in "note_note", with: "Good snippet!"
      click_button "Add Comment"
    end
  end

  Then 'I should see comment "Good snippet!"' do
    page.should have_content "Good snippet!"
  end

  And 'I visit snippet page "Snippet one"' do
    visit project_snippet_path(project, project_snippet)
  end

  def project
    @project ||= Project.find_by!(name: "Shop")
  end

  def project_snippet
    @project_snippet ||= ProjectSnippet.find_by!(title: "Snippet one")
  end
end
