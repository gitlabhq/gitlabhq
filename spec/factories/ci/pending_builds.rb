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
        pending_build.tag_ids = ::Ci::Tag.find_or_create_all_with_like_by_name(job.tag_list).map(&:id)
      end
    end
  end
end
