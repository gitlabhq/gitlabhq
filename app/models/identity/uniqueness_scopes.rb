# frozen_string_literal: true

class Identity < ApplicationRecord
  # This module and method are defined in a separate file to allow EE to
  # redefine the `scopes` method before it is used in the `Identity` model.
  module UniquenessScopes
    def self.scopes
      [:provider]
    end
  end
end

Identity::UniquenessScopes.prepend_mod_with('Identity::UniquenessScopes')
