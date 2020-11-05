# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::InvitationInterface do
  it 'exposes the expected fields' do
    expected_fields = %i[
      email
      access_level
      created_by
      created_at
      updated_at
      expires_at
      user
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '.resolve_type' do
    subject { described_class.resolve_type(object, {}) }

    context 'for project member' do
      let(:object) { build(:project_member) }

      it { is_expected.to be Types::ProjectInvitationType }
    end

    context 'for group member' do
      let(:object) { build(:group_member) }

      it { is_expected.to be Types::GroupInvitationType }
    end

    context 'for an unknown type' do
      let(:object) { build(:user) }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::BaseError)
      end
    end
  end
end
