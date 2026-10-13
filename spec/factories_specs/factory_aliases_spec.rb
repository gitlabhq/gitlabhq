# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Factory association aliases', feature_category: :tooling do
  row = FactoryDefaults::Row

  it_behaves_like 'factory default associations', [
    row.new(
      factory: :group_member, skip: :group, passed: { group: :group },
      expected: ->(group, _) { { source: group, member_namespace_id: group.id } }
    ),
    row.new(
      factory: :project_member, skip: :project, passed: { project: :project },
      expected: ->(project, strategy) {
        { source: project, member_namespace_id: strategy == :create ? project.project_namespace_id : project.id }
      }
    ),
    row.new(
      factory: :oauth_access_token, skip: :user, passed: { user: :user, resource_owner: :user },
      expected: ->(user, strategy) {
        strategy == :create ? { resource_owner: user, user: user } : { resource_owner: user }
      },
      setup: -> { { application: create(:oauth_application), organization: create(:organization) } }
    ),
    row.new(
      factory: :todo, skip: %i[issue project], passed: { issue: :issue },
      expected: ->(issue, _) { { issue: equal(issue), target: issue, target_id: issue.id, target_type: 'Issue' } }
    ),
    row.new(
      factory: :custom_emoji, skip: :group, passed: { namespace: :group, group: :group },
      expected: ->(group, _) { { group: group, namespace: group, namespace_id: group.id } }
    ),
    row.new(
      factory: :notification_setting, skip: :project, passed: { project: :project, source: :group },
      expected: ->(source, _) { { source: source, source_id: source.id, source_type: source.class.base_class.name } }
    ),
    row.new(
      factory: :ci_runner_namespace, skip: :group, passed: { namespace: :group, group: :group },
      expected: ->(group, _) { { namespace: group, group: group } },
      setup: -> { { runner: create(:ci_runner, :group, groups: [create(:group)]) } }
    ),
    row.new(factory: :label, skip: :project, passed: { parent_container: :project }),
    row.new(factory: :group_label, skip: :group, passed: { parent_container: :group }),
    row.new(factory: :label_link, skip: :label, passed: { own_label: :label }),
    row.new(factory: :ci_sources_pipeline, skip: :ci_build, passed: { build: :ci_build }),
    row.new(factory: :resource_link_event, skip: :issue, passed: { work_item: :work_item }),
    row.new(factory: :debian_project_distribution, skip: :project, passed: { project: :project }),
    row.new(factory: :debian_group_distribution, skip: :group, passed: { group: :group }),
    row.new(factory: :debian_package, skip: :project, passed: { project: :project })
  ]

  describe ':ci_runner_namespace defaults' do
    %i[build build_stubbed].each do |strategy|
      it "sets group and namespace to the same default record with #{strategy}" do
        record = public_send(strategy, :ci_runner_namespace)

        expect(record.namespace).to be_present
        expect(record.group).to equal(record.namespace)
      end
    end
  end
end
