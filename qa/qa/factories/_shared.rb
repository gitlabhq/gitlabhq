# frozen_string_literal: true

module QA
  FactoryBot.define do
    to_create do |instance|
      instance.class.fabricate_via_api!(resource: instance)
    end
  end
end
