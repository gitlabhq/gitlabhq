# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Checks for potential wildcard injection vulnerabilities in LIKE queries
      #
      # This cop detects dangerous patterns where user input could be used directly
      # in LIKE queries without proper sanitization, potentially leading to
      # wildcard injection attacks.
      #
      # @example
      #   # bad
      #   where("name LIKE '%#{term}%'")
      #   where("title LIKE ?", "#{pattern}%")
      #
      #   # good
      #   where("name LIKE ?", "%#{sanitize_sql_like(term)}%")
      #   where("title LIKE ?", sanitize_sql_like(pattern))
      class PreventWildcardInjection < RuboCop::Cop::Base
        RESTRICT_ON_SEND = [:where, :not, :exists?].freeze
        ALLOWED_METHODS = %w[sanitize_sql_like sanitized Gitlab::SQL::Glob.to_like].freeze

        MSG = "Wildcard injection vulnerability detected, " \
          "use `sanitize_sql_like` to escape user input in LIKE queries. " \
          "See https://edgeapi.rubyonrails.org/classes/ActiveRecord/Sanitization/ClassMethods.html#method-i-sanitize_sql_like"

        # @!method string_interpolation?(node)
        def_node_matcher :string_interpolation?, <<-PATTERN
          (dstr ...)
        PATTERN

        def on_send(node)
          return unless has_like_with_interpolation?(node)
          return if uses_sanitize_sql_like?(node)

          add_offense(node.loc.selector)
        end
        alias_method :on_csend, :on_send

        private

        def has_like_with_interpolation?(node)
          node.arguments.any? do |arg|
            if string_interpolation?(arg)
              contains_like?(arg.source)
            elsif arg.str_type?
              contains_like?(arg.value) && has_interpolated_params?(node)
            else
              false
            end
          end
        end

        def has_interpolated_params?(node)
          node.arguments.any? { |arg| string_interpolation?(arg) }
        end

        def uses_sanitize_sql_like?(node)
          node.arguments.any? do |arg|
            ALLOWED_METHODS.any? { |method| arg.source.include?(method) }
          end
        end

        def contains_like?(str_value)
          str_value.to_s.upcase.include?('LIKE')
        end
      end
    end
  end
end
