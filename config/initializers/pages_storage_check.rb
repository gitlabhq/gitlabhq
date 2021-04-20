# frozen_string_literal: true

# This is to make sure at least one storage strategy for Pages is enabled.

pages = Settings.pages

return unless pages['enabled'] && pages['local_store']

local_store_enabled = Gitlab::Utils.to_boolean(pages['local_store']['enabled'])
object_store_enabled = Gitlab::Utils.to_boolean(pages['object_store']['enabled'])

if !local_store_enabled && !object_store_enabled
  raise "Please enable at least one of the two Pages storage strategy (local_store or object_store) in your config/gitlab.yml."
end
