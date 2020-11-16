# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomEmoji'] do
  specify { expect(described_class.graphql_name).to eq('CustomEmoji') }

  specify { expect(described_class).to require_graphql_authorizations(:read_custom_emoji) }

  specify { expect(described_class).to have_graphql_fields(:id, :name, :url, :external) }
end
