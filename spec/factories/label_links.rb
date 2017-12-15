FactoryBot.define do
  factory :label_link do
    label
    target factory: :issue
  end
end
