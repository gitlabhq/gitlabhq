# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approve, class: 'Approve' do
    merge_request
    user
  end
end
