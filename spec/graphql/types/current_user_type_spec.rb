# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CurrentUser'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('CurrentUser') }

  it "inherits authorization policies from the UserType superclass" do
    expect(described_class).to require_graphql_authorizations(:read_user)
  end
end
