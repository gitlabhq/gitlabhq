# frozen_string_literal: true

require 'rubocop/cop/mixin/active_record_helper'
require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Database
      # Checks the use of .pluck(:attribute) without setting a limit.
      #
      # @example
      #
      #   # bad
      #   def all
      #     Project.where(user_id: User.pluck(:id))
      #   end
      #
      #   # good
      #   def all(limit)
      #     Project.where(user_id: User.limit(limit).pluck(:id))
      #   end
      class AvoidUsingPluckWithoutLimit < RuboCop::Cop::Base
        include RuboCop::Cop::ActiveRecordHelper
        include RuboCop::CodeReuseHelpers

        MSG = 'Avoid using `pluck` without defining a proper `limit`. ' \
              'Querying with too much values inside an `IN` clause can result in database performance degradation. ' \
              'See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17168'

        RESTRICT_ON_SEND = %i[pluck].freeze

        def_node_matcher :pluck_with_limit?, <<~PATTERN
        (send (send _ :limit _) ...)
        PATTERN

        def on_send(node)
          return unless should_scan?(node)

          return if pluck_with_limit?(node)

          add_offense(node.loc.selector)
        end

        private

        # It limits the check to ActiveRecord, Models, Finders and Service classes
        def should_scan?(node)
          inherit_active_record_base?(node) || in_model?(node) || in_finder?(node) || in_service_class?(node)
        end
      end
    end
  end
end
