# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NotePermissions'] do
  it 'has the expected fields' do
    expected_permissions = [
      :read_note, :create_note, :admin_note, :resolve_note, :reposition_note, :award_emoji
    ]

    expect(described_class).to have_graphql_fields(expected_permissions).only
  end
end
