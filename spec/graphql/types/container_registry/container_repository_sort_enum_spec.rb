# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositorySort'], feature_category: :container_registry do
  specify { expect(described_class.graphql_name).to eq('ContainerRepositorySort') }

  it_behaves_like 'common sort values'

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(
      *%w[NAME_ASC NAME_DESC]
    )
  end
end
