Given /^I visit project wiki page$/ do
  visit project_wiki_path(@project, :index)
end

Given /^I create Wiki page$/ do
  fill_in "Title", :with => 'Test title'
  fill_in "Content", :with => '[link test](test)'
  click_on "Save"
end

Then /^I should see newly created wiki page$/ do
  page.should have_content("Test title")
  page.should have_content("link test")

  click_link "link test"

  page.should have_content("Editing page")
end
