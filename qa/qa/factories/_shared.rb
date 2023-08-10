# frozen_string_literal: true

module QA
  FactoryBot.define do
    to_create(&:fabricate_via_api!)
  end
end
