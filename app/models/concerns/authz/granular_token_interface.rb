# frozen_string_literal: true

module Authz
  # Contract for token models that participate in granular scope authorization
  # (see Authz::Tokens::AuthorizeGranularScopesService). Including this module
  # marks a token class as supporting granular scopes.
  #
  # Includers must provide:
  # - #granular?: whether the token carries granular scopes
  # - #granular_scopes: the token's Authz::GranularScope collection
  #   (an ActiveRecord association or any enumerable)
  module GranularTokenInterface
    extend ActiveSupport::Concern

    include PolicyActor

    def legacy?
      !granular?
    end

    def permitted_for_boundary?(boundary, permissions)
      return false if legacy?

      if self.class.respond_to?(:reflect_on_association) &&
          self.class.reflect_on_association(:granular_scopes) &&
          !granular_scopes.loaded?
        ActiveRecord::Associations::Preloader.new(
          records: [self],
          associations: :granular_scopes
        ).call
      end

      required_permissions = Array(permissions).map(&:to_sym)
      token_permissions = granular_scopes
        .select { |granular_scope| granular_scope.applicable_to_boundary?(boundary) }
        .flat_map(&:expanded_permissions)

      (required_permissions - token_permissions).empty?
    end
  end
end
