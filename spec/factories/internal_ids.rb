FactoryBot.define do
  factory :internal_id do
    project
    usage { InternalId.usages.keys.first }
  end
end
