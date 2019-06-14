require 'spec_helper'

describe GitlabSchema.types['NotePermissions'] do
  it 'has the expected fields' do
    expected_permissions = [
      :read_note, :create_note, :admin_note, :resolve_note, :award_emoji
    ]

    is_expected.to have_graphql_fields(expected_permissions)
  end
end
