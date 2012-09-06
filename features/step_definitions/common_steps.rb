include LoginHelpers

Given /^I signin as a user$/ do
  login_as :user
end

When /^I click link "(.*?)"$/ do |link|
  click_link link
end

When /^I click button "(.*?)"$/ do |button|
  click_button button
end

When /^I fill in "(.*?)" with "(.*?)"$/ do |field, value|
  fill_in field, :with => value
end

Given /^show me page$/ do
  save_and_open_page
end
