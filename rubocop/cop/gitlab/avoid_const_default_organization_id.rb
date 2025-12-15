# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Flags usages of DEFAULT_ORGANIZATION_ID constant
      #
      # @example
      #   # bad
      #   Organizations::Organization::DEFAULT_ORGANIZATION_ID
      #   ::Organizations::Organization::DEFAULT_ORGANIZATION_ID
      #   DEFAULT_ORGANIZATION_ID = 1
      #
      # @example Good - using specific lookup methods
      #   # good
      #   Organizations::Organization.find(id)
      #   project.organization
      #   namespace.organization
      class AvoidConstDefaultOrganizationId < RuboCop::Cop::Base
        MSG = 'Avoid using `DEFAULT_ORGANIZATION_ID`. ' \
          'Consider looking up the organization with #find or inferring it from another model. ' \
          'See https://docs.gitlab.com/development/organization/#the-default-organization.'

        CONST_NAME = :DEFAULT_ORGANIZATION_ID

        def on_const(node)
          return unless node.children.last == CONST_NAME

          add_offense(node)
        end

        def on_casgn(node)
          return unless node.name == CONST_NAME

          add_offense(node)
        end
      end
    end
  end
end
