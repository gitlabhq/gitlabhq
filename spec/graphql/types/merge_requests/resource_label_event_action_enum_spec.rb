# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::ResourceLabelEventActionEnum, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('ResourceLabelEventAction') }

  it 'exposes all the existing resource label event actions' do
    expect(described_class.values.keys).to match_array(::ResourceLabelEvent.actions.keys.map(&:upcase))
  end

  it 'maps each value back to its underlying action' do
    expect(described_class.values['ADD'].value).to eq('add')
    expect(described_class.values['REMOVE'].value).to eq('remove')
  end
end
