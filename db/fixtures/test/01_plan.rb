require './spec/support/sidekiq'

Plan.create!(name: EE::Namespace::FREE_PLAN,
             title: EE::Namespace::FREE_PLAN.titleize)

EE::Namespace::EE_PLANS.each_key do |plan|
  Plan.create!(name: plan, title: plan.titleize)
end
