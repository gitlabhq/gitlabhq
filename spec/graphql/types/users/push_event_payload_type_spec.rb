# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PushEventPayload'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('PushEventPayload') }

  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_fields(:action, :ref, :commit)
  end
end
