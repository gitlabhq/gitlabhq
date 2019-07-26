# frozen_string_literal: true

FactoryBot.define do
  factory :term, class: ApplicationSetting::Term do
    terms "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
  end
end
