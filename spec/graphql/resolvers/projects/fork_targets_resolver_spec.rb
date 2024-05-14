# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::ForkTargetsResolver do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, path: 'namespace-group') }
  let_it_be(:another_group) { create(:group, path: 'namespace-another-group') }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:user) { create(:user, username: 'namespace-user', maintainer_of: project) }

  let(:args) { { search: 'namespace' } }

  describe '#resolve' do
    before_all do
      group.add_owner(user)
      another_group.add_owner(user)
    end

    it 'returns forkable namespaces' do
      expect_next_instance_of(ForkTargetsFinder) do |finder|
        expect(finder).to receive(:execute).with(args).and_call_original
      end

      expect(resolve_targets(args).items).to match_array([user.namespace, project.namespace, another_group])
    end
  end

  context 'when a user cannot fork the project' do
    let(:user) { create(:user) }

    it 'does not return results' do
      project.add_guest(user)

      expect(resolve_targets(args)).to be_nil
    end
  end

  def resolve_targets(args, opts = {})
    field_options = { owner: resolver_parent, resolver: described_class }.merge(opts)
    field = ::Types::BaseField.from_options('field_value', **field_options)
    resolve_field(field, project, args: args, ctx: { current_user: user }, object_type: resolver_parent)
  end
end
