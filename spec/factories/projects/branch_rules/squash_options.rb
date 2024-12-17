# frozen_string_literal: true

FactoryBot.define do
  factory :branch_rule_squash_option, class: 'Projects::BranchRules::SquashOption' do
    protected_branch

    trait :always do
      squash_option { :always }
    end

    trait :never do
      squash_option { :never }
    end

    trait :default_on do
      squash_option { :default_on }
    end

    trait :default_off do
      squash_option { :default_off }
    end
  end
end
