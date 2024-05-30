# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { nil }
    let_it_be(:user) { create(:user) }

    shared_examples 'queries user' do
      context 'authenticated access' do
        let_it_be(:current_user) { create(:user) }

        it 'returns the correct user' do
          expect(
            resolve_user(args)
          ).to eq(user)
        end
      end

      context 'unauthenticated access' do
        it 'forbids search' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolve_user(args)
          end
        end
      end
    end

    context 'by username' do
      include_examples "queries user" do
        let(:args) { { username: user.username } }
      end
    end

    context 'by ID' do
      include_examples "queries user" do
        let(:args) { { id: user.to_global_id } }
      end
    end
  end

  private

  def resolve_user(args = {}, context = { current_user: current_user })
    sync(resolve(described_class, args: args, ctx: context))
  end
end
