# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupMembers::NotificationEmailResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:group) { create(:group) }
    let_it_be(:developer) { create(:user) }

    before do
      group.add_developer(developer)
    end

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::String)
    end

    subject { batch_sync { resolve_notification_email(developer.group_members.first, current_user) } }

    context 'when current_user is admin' do
      let(:current_user) { create(:user, :admin) }

      before do
        allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it 'returns email' do
        expect(subject).to eq(developer.email)
      end
    end

    context 'when current_user is not admin' do
      let(:current_user) { create(:user) }

      it 'raises ResourceNotAvailable error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          subject
        end
      end
    end
  end

  def resolve_notification_email(obj, user)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
