# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Key'], feature_category: :system_access do
  specify { expect(described_class.graphql_name).to eq('Key') }
  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'contains attributes for SSH keys' do
    expect(described_class).to have_graphql_fields(
      :id, :title, :created_at, :expires_at, :key, :web_url, :name
    )
  end
end
