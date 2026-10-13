# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::ResourceLabelEventType, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestResourceLabelEvent') }

  specify { expect(described_class).to require_graphql_authorizations(:read_resource_label_event) }

  it 'exposes the expected fields' do
    expected_fields = %i[id action created_at label user]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::ResourceLabelEvent]) }
  end

  describe 'action' do
    subject { described_class.fields['action'] }

    it { is_expected.to have_non_null_graphql_type(Types::MergeRequests::ResourceLabelEventActionEnum) }
  end

  describe 'created_at' do
    subject { described_class.fields['createdAt'] }

    it { is_expected.to have_non_null_graphql_type(Types::TimeType) }
  end

  describe 'label' do
    subject { described_class.fields['label'] }

    it { is_expected.to have_graphql_type(Types::LabelType) }
  end

  describe 'user' do
    subject { described_class.fields['user'] }

    it { is_expected.to have_graphql_type(Types::UserType) }
  end
end
