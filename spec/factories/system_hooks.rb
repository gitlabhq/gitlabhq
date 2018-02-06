FactoryBot.define do
  factory :system_hook do
    url { generate(:url) }
  end
end
