# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['AwardEmoji'] do
  it { expect(described_class.graphql_name).to eq('AwardEmoji') }

  it { is_expected.to require_graphql_authorizations(:read_emoji) }

  it { expect(described_class).to have_graphql_fields(:description, :unicode_version, :emoji, :name, :unicode, :user) }
end
