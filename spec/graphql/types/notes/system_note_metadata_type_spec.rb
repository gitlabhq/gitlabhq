# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SystemNoteMetadata'], feature_category: :team_planning do
  it { expect(described_class).to have_graphql_field(:id) }
  it { expect(described_class).to have_graphql_field(:action) }
  it { expect(described_class).to have_graphql_field(:description_version) }

  specify { expect(described_class).to require_graphql_authorizations(:read_note) }
end
