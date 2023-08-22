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
    let(:args) { { from_line: 1, to_line: 2 } }

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

      context 'when feature is disabled' do
        before do
          stub_feature_flags(graphql_git_blame: false)
        end

        it 'returns nothing' do
          expect(subject).to be_nil
        end
      end

      shared_examples 'argument error' do
        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError,
            '`from_line` and `to_line` must be greater than or equal to 1') do
            resolve_blame
          end
        end
      end

      context 'when feature is enabled' do
        context 'when from_line is below 1' do
          let(:args) { { from_line: 0, to_line: 2 } }

          it_behaves_like 'argument error'
        end

        context 'when to_line is below 1' do
          let(:args) { { from_line: 1, to_line: 0 } }

          it_behaves_like 'argument error'
        end

        context 'when to_line less than from_line' do
          let(:args) { { from_line: 3, to_line: 1 } }

          it 'returns blame object' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError,
              '`to_line` must be greater than or equal to `from_line`') do
              resolve_blame
            end
          end
        end

        it 'returns blame object' do
          expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
        end
      end
    end
  end
end
