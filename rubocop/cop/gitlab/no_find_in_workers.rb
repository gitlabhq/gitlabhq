# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for use of ActiveRecord find in Sidekiq workers.
      #
      # @example
      #   # bad
      #   class ExampleWorker
      #     def perform
      #       record = Klass.find(id)
      #     end
      #   end
      #
      #   # good
      #   class ExampleWorker
      #     def perform
      #       record = Klass.find_by_id(id)
      #       return unless record
      #     end
      #   end
      #
      class NoFindInWorkers < RuboCop::Cop::Base
        DOC_LINK = 'https://docs.gitlab.com/ee/development/sidekiq/#retries'

        RESTRICT_ON_SEND = [:find].freeze

        MSG = <<~MSG.freeze
          Refrain from using `find`, use `find_by` instead. See #{DOC_LINK}.
        MSG

        def_node_matcher :find_method?, <<~PATTERN
          (send _ :find ...)
        PATTERN

        def on_send(node)
          add_offense(node, message: MSG)
        end
      end
    end
  end
end
