# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AwardEmoji'] do
  specify { expect(described_class.graphql_name).to eq('AwardEmoji') }

  specify { expect(described_class).to require_graphql_authorizations(:read_emoji) }

  specify { expect(described_class).to have_graphql_fields(:description, :unicode_version, :emoji, :name, :unicode, :user) }
end
