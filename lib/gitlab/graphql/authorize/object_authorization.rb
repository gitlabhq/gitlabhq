# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class ObjectAuthorization
        attr_reader :abilities, :permitted_scopes

        def initialize(abilities, scopes = %i[api read_api])
          @abilities = Array.wrap(abilities).flatten
          @permitted_scopes = Array.wrap(scopes)
        end

        def none?
          abilities.empty?
        end

        def any?
          abilities.present?
        end

        def ok?(object, current_user, scope_validator: nil)
          scopes_ok?(scope_validator) && abilities_ok?(object, current_user)
        end

        private

        def abilities_ok?(object, current_user)
          return true if none?

          subject = object.try(:declarative_policy_subject) || object
          abilities.all? do |ability|
            Ability.allowed?(current_user, ability, subject)
          end
        end

        def scopes_ok?(validator)
          return true unless validator.present?

          validator.valid_for?(permitted_scopes)
        end
      end
    end
  end
end
