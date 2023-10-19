# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        # The Node class allows us to traverse PgQuery nodes with tree like semantics.
        #
        # This class balances convenience and performance. The PgQuery nodes are Google::Protobuf::MessageExts which
        # contain a dynamic set of attributes known as fields. Accessing these fields can cause performance problems
        # due to the large volume of iterable fields.
        #
        # When possible use #dig over the *descendant* methods.
        #
        # The filter available to each method reduces the traversed attributes. The default filter only traverses nodes
        # required to parse for set operator mismatches.
        class Node
          class << self
            include Gitlab::Utils::StrongMemoize

            # The default nodes help speed up traversal. Traversal of other nodes can greatly affect performance.
            DEFAULT_NODES = %i[
              a_star
              alias
              args
              column_ref
              fields
              func_call
              join_expr
              larg
              range_subselect
              range_var
              rarg
              res_target
              subquery
              val
            ].freeze
            DEFAULT_FIELD_FILTER = ->(field) { field.is_a?(Integer) || DEFAULT_NODES.include?(field) }.freeze

            # Recurse through children.
            # The block will yield the child node and the name of that node.
            # Calling without a block will return an Enumerator.
            def descendants(node, filter: DEFAULT_FIELD_FILTER, &blk)
              if blk
                children(node, filter: filter) do |child_node, child_field|
                  yield(child_node, child_field)

                  descendants(child_node, filter: filter, &blk)
                end
                nil
              else
                enum_for(:descendants, node, filter: filter, &blk)
              end
            end

            # Return the first node that matches the field.
            def locate_descendant(node, field, filter: DEFAULT_FIELD_FILTER)
              descendants(node, filter: filter).find { |_, child_field| child_field == field }&.first
            end

            # Return all nodes that match the field.
            def locate_descendants(node, field, filter: DEFAULT_FIELD_FILTER)
              descendants(node, filter: filter).select { |_, child_field| child_field == field }.map(&:first)
            end

            # Like Hash#dig, traverse attributes in sequential order and return the final value.
            # Return nil if any of the fields are not available.
            def dig(node, *attrs)
              obj = node
              attrs.each do |attr|
                if obj.respond_to?(attr)
                  obj = obj.public_send(attr) # rubocop:disable GitlabSecurity/PublicSend
                else
                  obj = nil
                  break
                end
              end
              obj
            end

            private

            # Interface with a PgQuery result as though it was a tree node.
            # All elements in a PgQuery result are ancestors of Google::Protobuf::AbstractMessage
            #
            # Based off PgQuery's treewalker https://github.com/pganalyze/pg_query/blob/main/lib/pg_query/treewalker.rb
            def children(node, filter: DEFAULT_FIELD_FILTER, &_blk)
              attributes = case node
                           when Google::Protobuf::MessageExts
                             descriptor_fields(node.class.descriptor)
                           when Google::Protobuf::RepeatedField
                             node.count.times.to_a
                           end

              attributes.select(&filter).each do |attr|
                attr_key = attr.is_a?(Symbol) ? attr.to_s : attr
                child = node[attr_key]
                next if child.nil?

                yield(child, attr)
              end
            end

            def descriptor_fields(descriptor)
              strong_memoize_with(:descriptor_fields, descriptor) do
                keys = []
                descriptor.each do |field|
                  keys << field.name.to_sym
                end
                keys
              end
            end
          end
        end
      end
    end
  end
end
