# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SavedReply'] do
  specify { expect(described_class.graphql_name).to eq('SavedReply') }

  it 'has all the required fields' do
    expect(described_class).to have_graphql_fields(:id, :content, :name)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_saved_replies) }
end
