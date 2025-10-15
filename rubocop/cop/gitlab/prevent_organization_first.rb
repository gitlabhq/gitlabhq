# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Prevents use of Organizations::Organization.first which can
      # lead to unpredictable behavior for our migration to cells.
      #
      # @example Bad - using first or first!
      #   # bad
      #   Organizations::Organization.first
      #   Organizations::Organization.first!
      #
      # @example Good - using specific lookup methods
      #   # good
      #   Organizations::Organization.find(id)
      #   project.organization
      #   namespace.organization
      class PreventOrganizationFirst < RuboCop::Cop::Base
        MSG = "Avoid using `Organizations::Organization.first` or `first!`. " \
          "Use `find`, `find_by`, or infer the organization from another model (e.g project.organization). " \
          "See https://gitlab.com/gitlab-org/gitlab/-/issues/535463."

        RESTRICT_ON_SEND = %i[first first!].freeze

        # @!method organization_first?(node)
        def_node_matcher :organization_first?, <<~PATTERN
          {
            (send
              (const
                (const {nil? cbase} :Organizations) :Organization)
              {:first :first!}
              ...)
            (send
              (const nil? :Organization)
              {:first :first!}
              ...)
          }
        PATTERN

        def on_send(node)
          return unless organization_first?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
