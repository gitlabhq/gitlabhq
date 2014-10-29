# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :git_hook do
    force_push_regex "MyString"
    deny_delete_tag false
    delete_branch_regex "MyString"
    project
    commit_message_regex "MyString"
  end
end
