# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Rails
        # Enforce `safe_format` for externalized strings with interpolations and `.html_safe`.
        #
        # @example
        #   # bad
        #   _('string %{open}foo%{close}').html_safe % { open: '<b>'.html_safe, close: '</b>'.html_safe }
        #   format(_('string %{open}foo%{close}').html_safe, open: '<b>'.html_safe, close: '</b>'.html_safe)
        #   _('foo').html_safe
        #
        #   # good
        #   safe_format(_('string %{open}foo%{close}'), tag_pair(tag.b, :open, :close))
        #   safe_format('foo')
        #
        #   # also good no `html_safe`
        #   format(_('string %{var} number'), var: var)
        #   _('string %{var} number') % { var: var }
        class SafeFormat < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Use `safe_format` to interpolate externalized strings. ' \
                'See https://docs.gitlab.com/ee/development/i18n/externalization.html#html'

          RESTRICT_ON_SEND = %i[_ s_ N_ n_].freeze

          def_node_matcher :wrapped_by?, <<~PATTERN
            ^(send _ %method ...)
          PATTERN

          def on_send(gettext)
            return unless wrapped_by?(gettext, method: :html_safe)
            return if wrapped_by?(gettext, method: :safe_format)

            call, args = find_call_and_args(gettext)

            node_to_replace = call
            node_to_replace = node_to_replace.parent if wrapped_by?(node_to_replace, method: :html_safe)
            node_to_replace = node_to_replace.parent if wrapped_by?(node_to_replace, method: :html_escape)

            add_offense(call.loc.selector) do |corrector|
              use_safe_format(corrector, node_to_replace, gettext, args)
            end
          end

          private

          def find_call_and_args(node)
            call = node
            args = []

            node.each_ancestor do |ancestor|
              break unless ancestor.send_type?

              case ancestor.send_type? && ancestor.method_name
              when :format
                call = ancestor
                args = ancestor.arguments.drop(1)
                break
              when :%
                call = ancestor
                args = ancestor.arguments
                break
              end
            end

            [call, args]
          end

          def use_safe_format(corrector, node, gettext, args)
            receiver = gettext.source

            if args&.any?
              args = unwrap_args(args)
                .then { |args| use_tag_pair(args) }
                .then { |args| sourcify_args(args) }

              corrector.replace(node, "safe_format(#{receiver}, #{args})")
            else
              corrector.replace(node, "safe_format(#{receiver})")
            end
          end

          def unwrap_args(args)
            return args[0].children if args[0].array_type? || args[0].hash_type?

            args
          end

          # Turns `open: '<b>'.html_safe, close: '</b>'.html_safe` into
          # `tag_pair(tag.b, :open, :close)`.
          def use_tag_pair(args)
            return args unless args.all?(&:pair_type?)

            pair_hash = args.to_h { |pair| [pair.key, pair.value] }
            seen = Hash.new { |hash, tag| hash[tag] = [] }
            tag_pairs = []

            args.each do |pair|
              # We only care about { a: '<b>'.html_safe }. Ignore the rest
              next unless pair.value.send_type? && pair.value.method?(:html_safe) && pair.value.receiver.str_type?

              # Extract the tag from `<b>` or `</b>`.
              tag = pair.value.receiver.value[%r{^</?(\w+)>}, 1]
              next unless tag

              seen[tag] << pair
              next unless seen[tag].size == 2

              closing_tag, opening_tag = seen[tag].sort_by { |pair| pair.value.receiver.value }
              pair_hash.delete(closing_tag.key)
              pair_hash.delete(opening_tag.key)

              keys = [opening_tag, closing_tag].map { |pair| pair.key.value.inspect }.join(", ")
              tag_pairs << "tag_pair(tag.#{tag}, #{keys})"

              seen[tag].clear
            end

            tag_pairs + pair_hash.keys.map(&:parent)
          end

          def sourcify_args(args)
            args.map { |arg| arg.respond_to?(:source) ? arg.source : arg }.join(', ')
          end
        end
      end
    end
  end
end
