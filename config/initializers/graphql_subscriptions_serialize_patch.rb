# frozen_string_literal: true

# Backport of two unreleased upstream security fixes to
# GraphQL::Subscriptions::Serialize, which round-trips user-controlled
# subscription arguments through ActionCable/Redis (see
# Gitlab::Graphql::Subscriptions::ActionCableWithLoadBalancing).
#
# Ported from graphql-ruby master. The bodies are reformatted, and the
# non-Array/Hash branches of dump_value are delegated to the gem via super:
#
# - https://github.com/rmosolgo/graphql-ruby/commit/a55c33b58c88d798b62f1096dbbb50d1791a194e
#   "Escape subscription serializer magic keys": a user-supplied Hash key such as
#   `__gid__` was indistinguishable from the serializer's own markers on load.
# - https://github.com/rmosolgo/graphql-ruby/commit/369383a19953c6d99aa502225df402743b9f3ffc
#   "Preserve subscription serializer round trips": round-trip regressions the
#   escaping fix would otherwise introduce.
#
# A third fix, "Restrict subscription timestamp deserialization" (44dfd056), was
# released in graphql 2.6.8 and comes from the gem itself, not from here.
#
# Issue: https://gitlab.com/gitlab-org/security/gitlab/-/work_items/1793

# Guard so we remember to delete this patch once upstream cuts a release.
unless Gem::Version.new(GraphQL::VERSION) == Gem::Version.new('2.6.10')
  raise <<~ERROR
    Gitlab::Patch::GraphqlSubscriptionsSerialize is pinned to graphql 2.6.10!

    The graphql gem has moved. Check whether the subscription serializer fixes
    listed in this file are in the new release.

    If they are, delete these files:
    - config/initializers/graphql_subscriptions_serialize_patch.rb
    - spec/initializers/graphql_subscriptions_serialize_patch_spec.rb

    If they are not, re-verify the patch against the new gem source and bump the
    version in this guard.
  ERROR
end

module Gitlab
  module Patch
    module GraphqlSubscriptionsSerialize
      SERIALIZE = ::GraphQL::Subscriptions::Serialize

      GLOBALID_KEY = SERIALIZE::GLOBALID_KEY
      SYMBOL_KEY = SERIALIZE::SYMBOL_KEY
      SYMBOL_KEYS_KEY = SERIALIZE::SYMBOL_KEYS_KEY
      TIMESTAMP_KEY = SERIALIZE::TIMESTAMP_KEY
      TIMESTAMP_FORMAT = SERIALIZE::TIMESTAMP_FORMAT
      OPEN_STRUCT_KEY = SERIALIZE::OPEN_STRUCT_KEY

      TIMESTAMP_CLASS_NAMES = SERIALIZE::TIMESTAMP_CLASS_NAMES
      HASH_KEY = "__graphql_hash__"
      RESERVED_KEYS = [GLOBALID_KEY, SYMBOL_KEY, SYMBOL_KEYS_KEY, TIMESTAMP_KEY, OPEN_STRUCT_KEY, HASH_KEY].freeze

      private

      # The two methods below are ported from graphql-ruby master and deliberately
      # kept structurally identical to it, so they can be diffed against upstream and
      # deleted cleanly once the fixes are released. Restructuring them to satisfy the
      # cops below would defeat that, so they are disabled rather than the code changed.
      # rubocop:disable Metrics/AbcSize -- Ported from graphql-ruby master
      # rubocop:disable Metrics/CyclomaticComplexity -- Ported from graphql-ruby master
      # rubocop:disable Metrics/PerceivedComplexity -- Ported from graphql-ruby master
      # rubocop:disable Rails/Pluck -- Ported from graphql-ruby master, which cannot use ActiveSupport
      # rubocop:disable Gitlab/KeysFirstAndValuesFirst -- Ported from graphql-ruby master
      def load_value(value)
        if value.is_a?(Array)
          is_gids = !value.empty? && value.all? { |v| v.is_a?(Hash) && v.size == 1 && v[GLOBALID_KEY] }
          if is_gids
            # Assume it's an array of global IDs
            ids = value.map { |v| v[GLOBALID_KEY] }
            GlobalID::Locator.locate_many(ids)
          else
            value.map { |item| load_value(item) }
          end
        elsif value.is_a?(Hash)
          if value.size == 1
            case value.keys.first # there's only 1 key
            when GLOBALID_KEY
              GlobalID::Locator.locate(value[GLOBALID_KEY])
            when SYMBOL_KEY
              value[SYMBOL_KEY].to_sym
            when TIMESTAMP_KEY
              timestamp_class_name, *timestamp_args = value[TIMESTAMP_KEY]
              timestamp_class = if TIMESTAMP_CLASS_NAMES.include?(timestamp_class_name)
                                  Object.const_get(timestamp_class_name, false)
                                end

              if defined?(ActiveSupport::TimeWithZone) && timestamp_class_name == ActiveSupport::TimeWithZone.name
                zone_name, timestamp_s = timestamp_args
                zone = ActiveSupport::TimeZone[zone_name]
                raise "Zone #{zone_name} not found, unable to deserialize" unless zone

                zone.strptime(timestamp_s, TIMESTAMP_FORMAT)
              elsif timestamp_class
                timestamp_s = timestamp_args.first
                timestamp_class.strptime(timestamp_s, TIMESTAMP_FORMAT)
              else
                raise ArgumentError, "Unsupported timestamp class: #{timestamp_class_name.inspect}"
              end
            when OPEN_STRUCT_KEY
              ostruct_values = load_value(value[OPEN_STRUCT_KEY])
              OpenStruct.new(ostruct_values) # rubocop:disable Style/OpenStructUse -- Matches upstream graphql-ruby behaviour
            when HASH_KEY
              value[HASH_KEY].each_with_object({}) do |(k, v), loaded_h|
                loaded_h[load_value(k)] = load_value(v)
              end
            else
              key = value.keys.first
              { key => load_value(value[key]) }
            end
          else
            loaded_h = {}
            sym_keys = value.fetch(SYMBOL_KEYS_KEY, [])
            symbol_key_values = sym_keys.is_a?(Hash) ? sym_keys : nil
            value.each do |k, v|
              next if k == SYMBOL_KEYS_KEY

              k = k.to_sym if !symbol_key_values && sym_keys.include?(k)
              loaded_h[k] = load_value(v)
            end

            symbol_key_values&.each do |k, v|
              loaded_h[k.to_sym] = load_value(v)
            end

            loaded_h
          end
        else
          value
        end
      end

      def dump_value(obj)
        if obj.is_a?(Array)
          obj.map { |item| dump_value(item) }
        elsif obj.is_a?(Hash)
          has_colliding_symbol_key = obj.any? { |k, _v| k.is_a?(Symbol) && obj.key?(k.to_s) }

          if obj.any? { |k, _v| RESERVED_KEYS.include?(k.to_s) }
            return { HASH_KEY => obj.map { |k, v| [dump_value(k.is_a?(Symbol) ? k : k.to_s), dump_value(v)] } }
          end

          symbol_keys = nil
          symbol_key_values = nil
          dumped_h = {}
          obj.each do |k, v|
            dumped_v = dump_value(v)
            if has_colliding_symbol_key && k.is_a?(Symbol)
              symbol_key_values ||= {}
              symbol_key_values[k.to_s] = dumped_v
            else
              dumped_h[k.to_s] = dumped_v
            end

            if !has_colliding_symbol_key && k.is_a?(Symbol)
              symbol_keys ||= Set.new
              symbol_keys << k.to_s
            end
          end

          if symbol_key_values
            dumped_h[SYMBOL_KEYS_KEY] = symbol_key_values
          elsif symbol_keys
            dumped_h[SYMBOL_KEYS_KEY] = symbol_keys.to_a
          end

          dumped_h
        else
          super
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Rails/Pluck
      # rubocop:enable Gitlab/KeysFirstAndValuesFirst
    end
  end
end

GraphQL::Subscriptions::Serialize.singleton_class.prepend(Gitlab::Patch::GraphqlSubscriptionsSerialize)
