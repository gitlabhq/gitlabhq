# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pending_build, class: 'Ci::PendingBuild' do
    build factory: :ci_build
    project
    protected { build.protected }
    instance_runners_enabled { true }
    namespace { project.namespace }
    minutes_exceeded { false }
    namespace_traversal_ids { project.namespace.traversal_ids }

    before(:create) do |pending_build|
      pending_build.build.tap do |job|
        pending_build.tag_ids = ::Ci::Tag.named(job.tag_list).ids
      end
    end
  end
end
