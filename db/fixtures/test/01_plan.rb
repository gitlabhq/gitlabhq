require './spec/support/sidekiq'

EE::Namespace::EE_PLANS.each_key do |plan|
  Plan.create!(name: plan, title: plan.titleize)
end
