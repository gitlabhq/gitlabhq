# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectRunnersResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  describe '#resolve' do
    subject(:resolve_scope) do
      resolve(
        described_class,
        obj: obj,
        ctx: { current_user: user },
        args: args,
        arg_style: :internal
      )
    end

    include_context 'runners resolver setup'

    let(:obj) { project }
    let(:args) { {} }

    context 'when user cannot see runners' do
      it 'returns Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_scope
        end
      end
    end

    context 'with user as project admin' do
      before do
        project.add_maintainer(user)
      end

      let(:available_runners) { [inactive_project_runner, offline_project_runner, group_runner, instance_runner] }

      it 'returns all runners available to the project' do
        expect(resolve_scope.items.to_a).to match_array(available_runners)
      end
    end

    context 'with obj set to nil' do
      let(:obj) { nil }

      it 'raises an error' do
        expect { resolve_scope }.to raise_error('Expected project missing')
      end
    end

    context 'with obj not set to project' do
      let(:obj) { build(:group) }

      it 'raises an error' do
        expect { resolve_scope }.to raise_error('Expected project missing')
      end
    end

    describe 'Allowed query arguments' do
      let(:finder) { instance_double(::Ci::RunnersFinder) }
      let(:args) do
        {
          status: 'online',
          type: :group_type,
          tag_list: ['active_runner'],
          search: 'abc',
          sort: :contacted_asc
        }
      end

      let(:expected_params) do
        {
          status_status: 'online',
          type_type: :group_type,
          tag_name: ['active_runner'],
          preload: {},
          search: 'abc',
          sort: 'contacted_asc',
          project: project
        }
      end

      it 'calls RunnersFinder with expected arguments' do
        allow(::Ci::RunnersFinder).to receive(:new).with(
          current_user: user, params: expected_params
        ).once.and_return(finder)

        allow(finder).to receive(:execute).once.and_return([:execute_return_value])

        expect(resolve_scope.items.to_a).to contain_exactly(:execute_return_value)
      end
    end
  end
end
