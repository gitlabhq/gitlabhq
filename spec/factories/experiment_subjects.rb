# frozen_string_literal: true

FactoryBot.define do
  factory :experiment_subject do
    experiment
    user
    variant { :control }
  end
end
