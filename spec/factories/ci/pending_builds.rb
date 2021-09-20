# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pending_build, class: 'Ci::PendingBuild' do
    build factory: :ci_build
    project
    protected { build.protected }
    instance_runners_enabled { true }
    namespace { project.namespace }
    minutes_exceeded { false }
    tag_ids { build.tags_ids }
    namespace_traversal_ids { project.namespace.traversal_ids }
  end
end
