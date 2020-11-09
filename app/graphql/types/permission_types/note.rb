# frozen_string_literal: true

module Types
  module PermissionTypes
    class Note < BasePermissionType
      graphql_name 'NotePermissions'

      abilities :read_note, :create_note, :admin_note, :resolve_note, :reposition_note, :award_emoji
    end
  end
end
