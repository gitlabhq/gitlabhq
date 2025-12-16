# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Flags usages of Organizations::Organization.default_organization
      # and Organization.default_organization
      #
      # @example Bad - Using .default_organization
      #   # bad
      #   Organizations::Organization.default_organization
      #   ::Organizations::Organization.default_organization
      #   Organization.default_organization
      #
      # @example Good - Using lookup methods or inferring from another model
      #   # good
      #   Organizations::Organization.find(id)
      #   project.organization
      #   namespace.organization
      class AvoidDefaultOrganization < RuboCop::Cop::Base
        MSG = 'Avoid using `Organizations::Organization.default_organization`. ' \
          'Consider finding the organization by ID or inferring it from another model (i.e project / group). ' \
          'See https://docs.gitlab.com/development/organization/#the-default-organization'

        # @!method default_organization_call?(node)
        def_node_matcher :default_organization_call?, <<~PATTERN
          (send
            {
              (const nil? :Organization)
              (const (const {nil? (cbase)} :Organizations) :Organization)
            }
            :default_organization)
        PATTERN

        def on_send(node)
          return unless default_organization_call?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
