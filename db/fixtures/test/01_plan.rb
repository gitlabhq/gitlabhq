require './spec/support/sidekiq'

Plan.seed(name: EE::Namespace::FREE_PLAN,
             title: EE::Namespace::FREE_PLAN.titleize)

EE::Namespace::NAMESPACE_PLANS_TO_LICENSE_PLANS.each_key do |plan|
  Plan.seed(name: plan, title: plan.titleize)
end
