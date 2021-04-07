# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class ObjectAuthorization
        attr_reader :abilities

        def initialize(abilities)
          @abilities = Array.wrap(abilities).flatten
        end

        def none?
          abilities.empty?
        end

        def any?
          abilities.present?
        end

        def ok?(object, current_user)
          return true if none?

          subject = object.try(:declarative_policy_subject) || object
          abilities.all? do |ability|
            Ability.allowed?(current_user, ability, subject)
          end
        end
      end
    end
  end
end
