# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Update do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:runner) { create(:ci_runner, active: true, locked: false, run_untagged: true) }

  let(:current_ctx) { { current_user: user } }
  let(:mutated_runner) { subject[:runner] }

  let(:mutation_params) do
    {
      id: runner.to_global_id,
      description: 'updated description'
    }
  end

  specify { expect(described_class).to require_graphql_authorizations(:update_runner) }

  describe '#resolve' do
    subject do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when the user cannot admin the runner' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with invalid params' do
      it 'raises an error' do
        mutation_params[:id] = "invalid-id"

        expect { subject }.to raise_error(::GraphQL::CoercionError)
      end
    end

    context 'when required arguments are missing' do
      let(:mutation_params) { {} }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, "missing keyword: :id")
      end
    end

    context 'when user can update runner', :enable_admin_mode do
      let(:admin_user) { create(:user, :admin) }
      let(:current_ctx) { { current_user: admin_user } }

      let(:mutation_params) do
        {
          id: runner.to_global_id,
          description: 'updated description',
          maximum_timeout: 900,
          access_level: 'ref_protected',
          active: false,
          locked: true,
          run_untagged: false,
          tag_list: %w(tag1 tag2)
        }
      end

      context 'with valid arguments' do
        it 'updates runner with correct values' do
          expected_attributes = mutation_params.except(:id, :tag_list)

          subject

          expect(subject[:errors]).to be_empty
          expect(subject[:runner]).to be_an_instance_of(Ci::Runner)
          expect(subject[:runner]).to have_attributes(expected_attributes)
          expect(subject[:runner].tag_list).to contain_exactly(*mutation_params[:tag_list])
          expect(runner.reload).to have_attributes(expected_attributes)
          expect(runner.tag_list).to contain_exactly(*mutation_params[:tag_list])
        end
      end

      context 'with out-of-range maximum_timeout and missing tag_list' do
        it 'returns a descriptive error' do
          mutation_params[:maximum_timeout] = 100
          mutation_params.delete(:tag_list)

          expect(subject[:errors]).to contain_exactly(
            'Maximum timeout needs to be at least 10 minutes',
            'Tags list can not be empty when runner is not allowed to pick untagged jobs'
          )
        end
      end
    end
  end
end
