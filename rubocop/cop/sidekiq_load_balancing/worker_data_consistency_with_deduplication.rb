# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module SidekiqLoadBalancing
      # This cop checks for including_scheduled: true option in idempotent Sidekiq workers that utilize load balancing capabilities.
      #
      # @example
      #
      # # bad
      # class BadWorker
      #   include ApplicationWorker
      #
      #   data_consistency :delayed
      #   idempotent!
      #
      #   def perform
      #   end
      # end
      #
      # # bad
      # class BadWorker
      #   include ApplicationWorker
      #
      #   data_consistency :delayed
      #
      #   deduplicate :until_executing
      #   idempotent!
      #
      #   def perform
      #   end
      # end
      #
      # # good
      # class GoodWorker
      #   include ApplicationWorker
      #
      #   data_consistency :delayed
      #
      #   deduplicate :until_executing, including_scheduled: true
      #   idempotent!
      #
      #   def perform
      #   end
      # end
      #
      class WorkerDataConsistencyWithDeduplication < RuboCop::Cop::Base
        include CodeReuseHelpers
        extend AutoCorrector

        HELP_LINK = 'https://docs.gitlab.com/ee/development/sidekiq_style_guide.html#scheduling-jobs-in-the-future'
        REPLACEMENT = ', including_scheduled: true'
        DEFAULT_STRATEGY = ':until_executing'

        MSG = <<~MSG
          Workers that declare either `:sticky` or `:delayed` data consistency become eligible for database load-balancing.
          In both cases, jobs are enqueued with a short delay.

          If you do want to deduplicate jobs that utilize load-balancing, you need to specify including_scheduled: true
          argument when defining deduplication strategy.

          See #{HELP_LINK} for a more detailed explanation of these settings.
        MSG

        def_node_search :application_worker?, <<~PATTERN
          `(send nil? :include (const nil? :ApplicationWorker))
        PATTERN

        def_node_search :idempotent_worker?, <<~PATTERN
          `(send nil? :idempotent!)
        PATTERN

        def_node_search :data_consistency_defined?, <<~PATTERN
          `(send nil? :data_consistency (sym {:sticky :delayed }))
        PATTERN

        def_node_matcher :including_scheduled?, <<~PATTERN
          `(hash <(pair (sym :including_scheduled) (%1)) ...>)
        PATTERN

        def_node_matcher :deduplicate_strategy?, <<~PATTERN
          `(send nil? :deduplicate (sym $_) $(...)?)
        PATTERN

        def on_class(node)
          return unless in_worker?(node)
          return unless application_worker?(node)
          return unless idempotent_worker?(node)
          return unless data_consistency_defined?(node)

          @strategy, options = deduplicate_strategy?(node)
          including_scheduled = false
          if options
            @deduplicate_options = options[0]
            including_scheduled = including_scheduled?(@deduplicate_options, :true) # rubocop:disable Lint/BooleanSymbol
          end

          @offense = !(including_scheduled || @strategy == :none)
        end

        def on_send(node)
          return unless offense

          if node.children[1] == :deduplicate
            add_offense(node.loc.expression) do |corrector|
              autocorrect_deduplicate_strategy(node, corrector)
            end
          elsif node.children[1] == :idempotent! && !strategy
            add_offense(node.loc.expression) do |corrector|
              autocorrect_missing_deduplicate_strategy(node, corrector)
            end
          end
        end

        private

        attr_reader :offense, :deduplicate_options, :strategy

        def autocorrect_deduplicate_with_options(corrector)
          if including_scheduled?(deduplicate_options, :false) # rubocop:disable Lint/BooleanSymbol
            replacement = deduplicate_options.source.sub("including_scheduled: false", "including_scheduled: true")
            corrector.replace(deduplicate_options.loc.expression, replacement)
          else
            corrector.insert_after(deduplicate_options.loc.expression, REPLACEMENT)
          end
        end

        def autocorrect_deduplicate_without_options(node, corrector)
          corrector.insert_after(node.loc.expression, REPLACEMENT)
        end

        def autocorrect_missing_deduplicate_strategy(node, corrector)
          indent_found = node.source_range.source_line =~ /^( +)/
          # Get indentation size
          whitespaces = Regexp.last_match(1).size if indent_found
          replacement = "deduplicate #{DEFAULT_STRATEGY}#{REPLACEMENT}\n"
          # Add indentation in the end since we are inserting a whole line before idempotent!
          replacement += ' ' * whitespaces.to_i
          corrector.insert_before(node.source_range, replacement)
        end

        def autocorrect_deduplicate_strategy(node, corrector)
          if deduplicate_options
            autocorrect_deduplicate_with_options(corrector)
          else
            autocorrect_deduplicate_without_options(node, corrector)
          end
        end
      end
    end
  end
end
