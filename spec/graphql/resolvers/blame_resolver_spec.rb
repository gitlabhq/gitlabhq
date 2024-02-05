# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BlameResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:path) { 'files/ruby/popen.rb' }
    let(:commit) { project.commit('master') }
    let(:blob) { project.repository.blob_at(commit.id, path) }
    let(:args) { { from_line: 1, to_line: 100 } }

    subject(:resolve_blame) { resolve(described_class, obj: blob, args: args, ctx: { current_user: user }) }

    context 'when unauthorized' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_blame
        end
      end
    end

    context 'when authorized' do
      before_all do
        project.add_developer(user)
      end

      shared_examples 'argument error' do |error_message|
        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError,
            error_message) do
            resolve_blame
          end
        end
      end

      context 'when feature is enabled' do
        context 'when from_line is below 1' do
          let(:args) { { from_line: 0, to_line: 2 } }

          it_behaves_like 'argument error', '`from_line` and `to_line` must be greater than or equal to 1'
        end

        context 'when to_line is below 1' do
          let(:args) { { from_line: 1, to_line: 0 } }

          it_behaves_like 'argument error', '`from_line` and `to_line` must be greater than or equal to 1'
        end

        context 'when to_line less than from_line' do
          let(:args) { { from_line: 3, to_line: 1 } }

          it_behaves_like 'argument error', '`to_line` must be greater than or equal to `from_line`'
        end

        context 'when difference between to_line and from_line is greater then 99' do
          let(:args) { { from_line: 3, to_line: 103 } }

          it_behaves_like 'argument error',
            '`to_line` must be greater than or equal to `from_line` and smaller than `from_line` + 100'
        end

        context 'when to_line and from_line are the same' do
          let(:args) { { from_line: 1, to_line: 1 } }

          it 'returns blame object' do
            expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
          end
        end

        it 'returns blame object' do
          expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
        end
      end
    end
  end
end
