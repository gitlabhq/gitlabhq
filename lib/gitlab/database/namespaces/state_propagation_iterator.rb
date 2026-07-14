# frozen_string_literal: true

module Gitlab
  module Database
    module Namespaces
      # Walks down a namespace tree in batches so we can copy a parent's state
      # onto its descendants.
      #
      # The walk only visits descendants whose current state we are allowed to
      # overwrite -- those states are passed in as `state_filter`. Anything in a
      # different state (and everything below it) is left alone.
      #
      # Why this subclass exists
      # ------------------------
      # State on a namespace can change while we are mid-walk. For example, we
      # might already be inside Subgroup B's subtree when someone schedules B
      # for deletion. From that moment on, we should not touch B or anything
      # under it -- but the plain tree walker has no way to notice and will keep
      # yielding ids from B's subtree.
      #
      # This class fixes that by checking, after every batch, whether any
      # ancestor on the path we just walked has changed into a state we are no
      # longer allowed to overwrite. If it has, we throw the batch away and
      # "rewind" the cursor so the next batch resumes from somewhere safe --
      # typically the next sibling above the affected subtree.
      #
      # See the ADR for the full design:
      # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/group_and_project_operations_and_state_management/decisions/003_state_propagation_model/
      class StatePropagationIterator < ::Gitlab::Database::NamespaceEachBatch
        def initialize(namespace_class:, cursor:, state_filter:)
          super(namespace_class: namespace_class, cursor: cursor)

          @state_filter = state_filter
          @root_id = @cursor[:current_id]
        end

        private

        attr_reader :state_filter

        # Called by the base iterator after each batch is loaded but before it
        # is yielded. We use it to react to ancestors that changed state while
        # we were walking:
        #
        #   - :continue       -- nothing changed, yield the batch as usual.
        #   - :stop           -- the propagation root itself changed, or there
        #                       is nowhere safe left to resume from. End the walk.
        #   - :reseed, cursor -- an ancestor changed; throw this batch away and
        #                       restart the walk from the rewound cursor (the
        #                       next safe place past the affected subtree).
        def next_iteration_action(new_cursor)
          boundary_id = detect_boundary(new_cursor)
          return [:continue, nil] unless boundary_id
          return [:stop, nil] if boundary_id == @root_id

          rewound = rewind_past_boundary(new_cursor, boundary_id)
          return [:stop, nil] if rewound.nil?

          [:reseed, rewound]
        end

        def namespace_exists_query
          super.with_state(state_filter)
        end

        def walk_down_lateral_query
          super.with_state(state_filter)
        end

        def next_elements_lateral_query
          super.with_state(state_filter)
        end

        # Look at every ancestor on the path we just walked and return the
        # first one (closest to the root) whose state is no longer in our
        # allow-list. That namespace is the "boundary" -- we must not touch it
        # or anything underneath it. Picking the shallowest one means the
        # rewind skips the biggest possible affected subtree.
        def detect_boundary(new_cursor)
          depth = new_cursor[:depth]
          return if depth.empty?

          boundary_ids = namespace_class.where(id: depth).where.not(state: state_filter).pluck(:id)
          return if boundary_ids.empty?

          boundary_ids.min_by { |id| depth.index(id) }
        end

        # Build a new cursor that lands just past the boundary's subtree so the
        # walk can pick up from there. We cannot simply restart at the boundary
        # itself -- the base walker would step right back into its children.
        #
        # Instead we look for the boundary's next sibling. If it has none, we
        # move up to the boundary's parent and look for its next sibling, and
        # so on up the tree. We prefer the deepest ancestor that has a sibling
        # we are still allowed to visit, so we resume as close to where we left
        # off as possible.
        #
        # Returns nil when no such sibling exists anywhere up the path, which
        # means the walk is finished.
        def rewind_past_boundary(new_cursor, boundary_id)
          depth = new_cursor[:depth]
          boundary_index = depth.index(boundary_id)

          pairs = (1..boundary_index).map { |i| [depth[i - 1], depth[i]] }
          siblings_by_parent = next_siblings_by_parent(pairs)

          rewound = nil
          boundary_index.downto(1) do |i|
            sibling_id = siblings_by_parent[depth[i - 1]]
            next unless sibling_id

            rewound = { current_id: sibling_id, depth: depth[0...i] + [sibling_id] }
            break
          end

          rewound
        end

        # For each [parent_id, after_id] pair, find the smallest eligible
        # sibling id under that parent that comes after after_id. Returned as
        # a { parent_id => sibling_id } hash.
        #
        # We answer all levels in one query so the rewind cost stays the same
        # whether the boundary is 2 or 20 levels deep.
        def next_siblings_by_parent(pairs)
          return {} if pairs.empty?

          table = namespace_class.arel_table
          or_conditions = pairs.map do |(parent_id, after_id)|
            table[:parent_id].eq(parent_id).and(table[:id].gt(after_id))
          end
          conditions = or_conditions.reduce { |acc, cond| acc.or(cond) }

          namespace_class
            .where(conditions, *pairs.flatten)
            .with_state(state_filter)
            .group(:parent_id)
            .pluck(:parent_id, Arel.sql('MIN(id)'))
            .to_h
        end
      end
    end
  end
end
