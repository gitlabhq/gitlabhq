# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PushEventRef'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('PushEventRef') }

  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_fields(:name, :type, :count)
  end
end
