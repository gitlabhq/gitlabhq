# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_custom_status_mapping, class: 'WorkItems::Statuses::Custom::Mapping' do
    namespace { association(:namespace) }
    work_item_type { association(:work_item_type) }
    old_status { association(:work_item_custom_status, namespace: namespace) }
    new_status { association(:work_item_custom_status, namespace: namespace) }
  end
end
