# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnersResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  describe '#resolve' do
    let(:obj) { nil }
    let(:args) { {} }

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

    # First, we can do a couple of basic real tests to verify common cases. That ensures that the code works.
    context 'when user cannot see runners' do
      let(:user) { build(:user) }

      it 'returns Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_scope
        end
      end
    end

    context 'when user can see runners' do
      let(:obj) { nil }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it 'returns all the runners' do
          expect(resolve_scope.items.to_a).to contain_exactly(
            inactive_project_runner, offline_project_runner, group_runner, subgroup_runner, instance_runner
          )
        end
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it 'returns all the runners' do
            expect(resolve_scope.items.to_a).to contain_exactly(
              inactive_project_runner, offline_project_runner, group_runner, subgroup_runner, instance_runner
            )
          end
        end

        context 'when not in admin mode' do
          it 'returns Gitlab::Graphql::Errors::ResourceNotAvailable' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
              resolve_scope
            end
          end
        end
      end
    end

    # Then, we can check specific edge cases for this resolver
    context 'with obj not set to nil' do
      let(:obj) { build(:project) }

      it 'raises an error' do
        expect { resolve_scope }.to raise_error(a_string_including('Unexpected parent type'))
      end
    end

    # Here we have a mocked part. We assume that all possible edge cases are covered in RunnersFinder spec. So we don't need to test them twice.
    # Only thing we can do is to verify that args from the resolver is correctly transformed to params of the Finder and we return the Finder's result back.
    describe 'Allowed query arguments' do
      let(:finder) { instance_double(::Ci::RunnersFinder) }

      context 'with active filter' do
        let(:args) do
          {
            active: true,
            status: 'offline',
            upgrade_status: 'recommended',
            type: :instance_type,
            tag_list: ['active_runner'],
            search: 'abc',
            sort: :contacted_asc,
            creator_id: 'gid://gitlab/User/1',
            creator_username: 'root',
            owner_wildcard: 'administrator',
            owner_full_path: '',
            version_prefix: '15.'
          }
        end

        let(:expected_params) do
          {
            active: true,
            status_status: 'offline',
            upgrade_status: 'recommended',
            type_type: :instance_type,
            tag_name: ['active_runner'],
            preload: {},
            search: 'abc',
            sort: 'contacted_asc',
            creator_id: '1',
            creator_username: 'root',
            owner: { wildcard: 'administrator', full_path: '' },
            version_prefix: '15.'
          }
        end

        it 'calls RunnersFinder with expected arguments' do
          expect(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
          allow(finder).to receive(:execute).once.and_return([:execute_return_value])

          expect(resolve_scope.items.to_a).to contain_exactly :execute_return_value
        end
      end

      context 'with both active and paused filter' do
        let(:args) do
          {
            active: true,
            paused: true
          }
        end

        let(:expected_params) do
          {
            active: false,
            preload: {}
          }
        end

        it 'calls RunnersFinder with expected arguments' do
          expect(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
          allow(finder).to receive(:execute).once.and_return([:execute_return_value])

          expect(resolve_scope.items.to_a).to contain_exactly :execute_return_value
        end
      end

      context 'with paused filter' do
        let(:args) do
          { paused: true }
        end

        let(:expected_params) do
          {
            active: false,
            preload: {}
          }
        end

        it 'calls RunnersFinder with expected arguments' do
          expect(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
          allow(finder).to receive(:execute).once.and_return([:execute_return_value])

          expect(resolve_scope.items.to_a).to contain_exactly :execute_return_value
        end
      end

      context 'with neither paused or active filters' do
        let(:args) do
          {}
        end

        let(:expected_params) do
          { preload: {} }
        end

        it 'calls RunnersFinder with expected arguments' do
          expect(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
          allow(finder).to receive(:execute).once.and_return([:execute_return_value])

          expect(resolve_scope.items.to_a).to contain_exactly :execute_return_value
        end
      end

      context 'with an invalid version filter parameter' do
        let(:args) do
          { version_prefix: 'a.b' }
        end

        let(:expected_params) do
          {
            preload: {},
            version_prefix: 'a.b'
          }
        end

        it 'ignores the parameter and returns runners' do
          expect(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
          allow(finder).to receive(:execute).once.and_return([:execute_return_value])

          expect(resolve_scope.items.to_a).to contain_exactly :execute_return_value
        end
      end
    end
  end
end
