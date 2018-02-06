require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # This cop requires a default value and disallows nulls for boolean
      # columns on small tables.
      #
      # In general, this prevents 3-state-booleans.
      # https://robots.thoughtbot.com/avoid-the-threestate-boolean-problem
      #
      # In particular, for the `application_settings` table, this ensures that
      # upgraded installations get a proper default for the new boolean setting.
      # A developer might otherwise mistakenly assume that a value in
      # `ApplicationSetting.defaults` is sufficient.
      #
      # See https://gitlab.com/gitlab-org/gitlab-ee/issues/2750 for more
      # information.
      class SaferBooleanColumn < RuboCop::Cop::Cop
        include MigrationHelpers

        DEFAULT_OFFENSE = 'Boolean columns on the `%s` table should have a default. You may wish to use `add_column_with_default`.'.freeze
        NULL_OFFENSE = 'Boolean columns on the `%s` table should disallow nulls.'.freeze
        DEFAULT_AND_NULL_OFFENSE = 'Boolean columns on the `%s` table should have a default and should disallow nulls. You may wish to use `add_column_with_default`.'.freeze

        SMALL_TABLES = %i[
          application_settings
        ].freeze

        def_node_matcher :add_column?, <<~PATTERN
          (send nil? :add_column $...)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          matched = add_column?(node)

          return unless matched

          table, _, type = matched.to_a.take(3).map(&:children).map(&:first)
          opts = matched[3]

          return unless SMALL_TABLES.include?(table) && type == :boolean

          no_default = no_default?(opts)
          nulls_allowed = nulls_allowed?(opts)

          offense = if no_default && nulls_allowed
                      DEFAULT_AND_NULL_OFFENSE
                    elsif no_default
                      DEFAULT_OFFENSE
                    elsif nulls_allowed
                      NULL_OFFENSE
                    end

          add_offense(node, location: :expression, message: format(offense, table)) if offense
        end

        def no_default?(opts)
          return true unless opts

          each_hash_node_pair(opts) do |key, value|
            return value == 'nil' if key == :default
          end
        end

        def nulls_allowed?(opts)
          return true unless opts

          each_hash_node_pair(opts) do |key, value|
            return value != 'false' if key == :null
          end
        end

        def each_hash_node_pair(hash_node, &block)
          hash_node.each_node(:pair) do |pair|
            key = hash_pair_key(pair)
            value = hash_pair_value(pair)
            yield(key, value)
          end
        end

        def hash_pair_key(pair)
          pair.children[0].children[0]
        end

        def hash_pair_value(pair)
          pair.children[1].source
        end
      end
    end
  end
end
