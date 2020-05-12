# frozen_string_literal: true

require 'spec_helper'

describe Types::Ci::DetailedStatusType do
  specify { expect(described_class.graphql_name).to eq('DetailedStatus') }

  it "has all fields" do
    expect(described_class).to have_graphql_fields(:group, :icon, :favicon,
                                                   :details_path, :has_details,
                                                   :label, :text, :tooltip)
  end
end
