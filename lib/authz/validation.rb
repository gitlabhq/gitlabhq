# frozen_string_literal: true

module Authz
  class Validation
    PERMISSION_NAME_REGEX = /\A[a-z]+_[a-z_]+[a-z]\z/

    COMMON_ACTIONS = {
      create: 'Creates a new resource',
      read: 'Views or retrieves a resource',
      update: 'Modifies an existing resource',
      delete: 'Removes a resource'
    }.freeze

    DISALLOWED_ACTIONS = {
      admin: 'a granular action',
      change: 'update',
      destroy: 'delete',
      edit: 'update',
      list: 'read',
      manage: 'a granular action',
      modify: 'update',
      set: 'update',
      view: 'read',
      write: 'a granular action'
    }.freeze
  end
end
