# frozen_string_literal: true

return unless Gitlab.ee?

Gitlab::CustomRoles::Definition.load_abilities!
