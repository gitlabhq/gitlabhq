class Spinach::Features::ProjectWiki < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths

  step 'I click on the Cancel button' do
    within(:css, ".form-actions") do
      click_on "Cancel"
    end
  end

  step 'I should be redirected back to the Edit Home Wiki page' do
    current_path.should == project_wiki_path(project, :home)
  end

  step 'I create the Wiki Home page' do
    fill_in "wiki_content", with: '[link test](test)'
    click_on "Create page"
  end

  step 'I should see the newly created wiki page' do
    page.should have_content "Home"
    page.should have_content "link test"

    click_link "link test"
    page.should have_content "Editing"
  end

  step 'I have an existing Wiki page' do
    wiki.create_page("existing", "content", :markdown, "first commit")
    @page = wiki.find_page("existing")
  end

  step 'I browse to that Wiki page' do
    visit project_wiki_path(project, @page)
  end

  step 'I click on the Edit button' do
    click_on "Edit"
  end

  step 'I change the content' do
    fill_in "Content", with: 'Updated Wiki Content'
    click_on "Save changes"
  end

  step 'I should see the updated content' do
    page.should have_content "Updated Wiki Content"
  end

  step 'I should be redirected back to that Wiki page' do
    current_path.should == project_wiki_path(project, @page)
  end

  step 'That page has two revisions' do
    @page.update("new content", :markdown, "second commit")
  end

  step 'I click the History button' do
    click_on "History"
  end

  step 'I should see both revisions' do
    page.should have_content current_user.name
    page.should have_content "first commit"
    page.should have_content "second commit"
  end

  step 'I click on the "Delete this page" button' do
    click_on "Delete this page"
  end

  step 'The page should be deleted' do
    page.should have_content "Page was successfully deleted"
  end

  step 'I click on the "Pages" button' do
    click_on "Pages"
  end

  step 'I should see the existing page in the pages list' do
    page.should have_content current_user.name
    page.should have_content @page.title
  end

  step 'I have an existing Wiki page with images linked on page' do
    wiki.create_page("pictures", "Look at this [image](image.jpg)\n\n ![image](image.jpg)", :markdown, "first commit")
    @wiki_page = wiki.find_page("pictures")
  end

  step 'I browse to wiki page with images' do
    visit project_wiki_path(project, @wiki_page)
  end

  step 'I click on existing image link' do
    file = Gollum::File.new(wiki.wiki)
    Gollum::Wiki.any_instance.stub(:file).with("image.jpg", "master", true).and_return(file)
    Gollum::File.any_instance.stub(:mime_type).and_return("image/jpeg")
    page.should have_link('image', href: "image.jpg")
    click_on "image"
  end

  step 'I should see the image from wiki repo' do
    current_path.should match('wikis/image.jpg')
    page.should_not have_xpath('/html') # Page should render the image which means there is no html involved
    Gollum::Wiki.any_instance.unstub(:file)
    Gollum::File.any_instance.unstub(:mime_type)
  end

  step 'Image should be shown on the page' do
    page.should have_xpath("//img[@src=\"image.jpg\"]")
  end

  step 'I click on image link' do
    page.should have_link('image', href: "image.jpg")
    click_on "image"
  end

  step 'I should see the new wiki page form' do
    current_path.should match('wikis/image.jpg')
    page.should have_content('New Wiki Page')
    page.should have_content('Editing - image.jpg')
  end

  def wiki
    @project_wiki = ProjectWiki.new(project, current_user)
  end
end
