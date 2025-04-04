# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GroupSort'], feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('GroupSort') }

  it 'exposes all the existing sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        SIMILARITY
        NAME_ASC
        NAME_DESC
        PATH_ASC
        PATH_DESC
        ID_ASC
        ID_DESC
      ]
    )
  end
end
