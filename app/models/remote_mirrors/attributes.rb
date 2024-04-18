# frozen_string_literal: true

# Provides access to remote mirror attributes
module RemoteMirrors
  class Attributes
    ALLOWED_ATTRIBUTES = %i[
      url
      enabled
      auth_method
      keep_divergent_refs
      only_protected_branches
      ssh_known_hosts
      user
      password
    ].freeze

    def initialize(attrs)
      @attrs = attrs
    end

    def allowed
      attrs.slice(*keys)
    end

    def keys
      ALLOWED_ATTRIBUTES
    end

    private

    attr_reader :attrs
  end
end

RemoteMirrors::Attributes.prepend_mod_with('RemoteMirrors::Attributes')
