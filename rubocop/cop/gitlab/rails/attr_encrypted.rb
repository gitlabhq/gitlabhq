# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Rails
        # Checks for usage of attr_encrypted
        # For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/26243
        #
        # @example
        #   # bad
        #   attr_encrypted :value
        #
        #   # good
        #   encrypts :value
        #
        class AttrEncrypted < RuboCop::Cop::Base
          extend AutoCorrector

          MSG = "Use `encrypts` over deprecated `attr_encrypted` to encrypt a column. " \
            "See https://docs.gitlab.com/development/migration_style_guide/#encrypted-attributes"

          RESTRICT_ON_SEND = [:attr_encrypted].freeze

          def on_send(node)
            add_offense(node) do |corrector|
              corrector.replace(node, "encrypts #{node.children[2].value.inspect}")
            end
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
