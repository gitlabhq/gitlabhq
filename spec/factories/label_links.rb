# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :label_link do
    label
    target factory: :issue
  end
end
