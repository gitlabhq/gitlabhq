FactoryBot.define do
  factory :internal_id do
    project
    type { InternalId.types.keys.first }
  end
end
