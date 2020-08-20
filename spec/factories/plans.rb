# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    Plan.all_plans.each do |plan|
      factory :"#{plan}_plan" do
        name { plan }
        title { name.titleize }
        initialize_with { Plan.find_or_create_by!(name: plan) }
      end
    end
  end
end
