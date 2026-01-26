# frozen_string_literal: true

module Enums # rubocop: disable Gitlab/BoundedContexts -- It's within CI domain
  module Ci
    module Variable
      TYPES = {
        env_var: 1,
        file: 2
      }.freeze
    end
  end
end
