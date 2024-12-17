# frozen_string_literal: true

FactoryBot.define do
  sequence(:username) { |n| "user#{n}" }
  sequence(:name) { |n| "Sidney Jones#{n}" }
  sequence(:email) { |n| "user#{n}@example.org" }
  sequence(:email_alias) { |n| "user.alias#{n}@example.org" }
  sequence(:title) { |n| "My title #{n}" }
  sequence(:filename) { |n| "filename-#{n}.rb" }
  sequence(:url) { |n| "http://example#{n}.test" }
  sequence(:label_title) { |n| "label#{n}" }
  sequence(:branch) { |n| "my-branch-#{n}" }
  sequence(:past_time) { |n| 4.hours.ago + (2 * n).seconds }
  sequence(:iid)
  sequence(:sha) { |n| Digest::SHA1.hexdigest("commit-like-#{n}") }
  sequence(:oid) { |n| Digest::SHA2.hexdigest("oid-like-#{n}") }
  sequence(:variable) { |n| "var#{n}" }
  sequence(:draft_title) { |n| "Draft: #{n}" }
  sequence(:jira_title) { |n| "[PROJ-#{n}]: fix bug" }
  sequence(:jira_description) { |n| "This is a description\n here is the description\n Related to: PROJ-#{n}" }
  sequence(:jira_branch) { |n| "feature/PROJ-#{n}" }
  sequence(:job_name) { |n| "job #{n}" }
  sequence(:short_text) { |n| "someText#{n}" }
  sequence(:token) { SecureRandom.hex(10) }
end
