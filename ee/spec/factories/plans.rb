# EE-only
FactoryBot.define do
  factory :plan do
    factory :free_plan do
      name EE::Namespace::FREE_PLAN
      title { name.titleize }
    end

    EE::Namespace::PLANS.each do |plan|
      factory :"#{plan}_plan" do
        name plan
        title { name.titleize }
      end
    end
  end
end
