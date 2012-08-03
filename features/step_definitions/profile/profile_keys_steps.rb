Given /^I visit profile keys page$/ do
  visit keys_path
end

Then /^I should see my ssh keys$/ do
  @user.keys.each do |key|
    page.should have_content(key.title)
  end
end

Given /^I have ssh keys:$/ do |table|
  table.hashes.each do |row|
    Factory :key, :user => @user, :title => row[:title], :key => "jfKLJDFKSFJSHFJ#{row[:title]}"
  end
end

Given /^I submit new ssh key "(.*?)"$/ do |arg1|
  fill_in "key_title", :with => arg1
  fill_in "key_key", :with => "publickey234="
  click_button "Save"
end

Then /^I should see new ssh key "(.*?)"$/ do |arg1|
  key = Key.find_by_title(arg1)
  page.should have_content(key.title)
  page.should have_content(key.key)
  current_path.should == key_path(key)
end

Then /^I should not see "(.*?)" ssh key$/ do |arg1|
  within "#keys-table" do
    page.should_not have_content(arg1)
  end
end
