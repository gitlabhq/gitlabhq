# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_descendants, class: 'Namespaces::Descendants' do
    namespace { association(:group) }
    self_and_descendant_group_ids { namespace.self_and_descendant_ids.pluck(:id).sort }
    all_project_ids { namespace.all_projects.pluck(:id).sort }
    traversal_ids { namespace.traversal_ids }
    outdated_at { nil }
    calculated_at { Time.current }
  end
end
