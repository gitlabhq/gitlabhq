# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    name { 'default' }
    plan_name_uid { ::Plan.plan_name_uids[name] }
    title { name.titleize }

    Plan.all_plans.each do |plan|
      factory :"#{plan}_plan" do
        name { plan }
        plan_name_uid { ::Plan.plan_name_uids[plan.downcase] }
        title { name.titleize }
        initialize_with { Plan.find_or_create_by!(name: plan) }
      end
    end
  end
end
