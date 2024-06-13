# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectSort'], feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('ProjectSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        ID_ASC ID_DESC LATEST_ACTIVITY_ASC LATEST_ACTIVITY_DESC
        NAME_ASC NAME_DESC PATH_ASC PATH_DESC STARS_ASC STARS_DESC
        STORAGE_SIZE_ASC STORAGE_SIZE_DESC
      ]
    )
  end
end
