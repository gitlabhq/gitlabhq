FactoryBot.define do
  sequence(:username) { |n| "user#{n}" }
  sequence(:name) { |n| "John Doe#{n}" }
  sequence(:email) { |n| "user#{n}@example.org" }
  sequence(:email_alias) { |n| "user.alias#{n}@example.org" }
  sequence(:title) { |n| "My title #{n}" }
  sequence(:filename) { |n| "filename-#{n}.rb" }
  sequence(:url) { |n| "http://example#{n}.org" }
  sequence(:label_title) { |n| "label#{n}" }
  sequence(:branch) { |n| "my-branch-#{n}" }
  sequence(:past_time) { |n| 4.hours.ago + (2 * n).seconds }
end
