# frozen_string_literal: true

# This module makes it possible to handle items as a list, where the order of items can be easily altered
# Requirements:
#
# The model must have the following named columns:
#  - id: integer
#  - relative_position: integer
#
# The model must support a concept of siblings via a child->parent relationship,
# to enable rebalancing and `GROUP BY` in queries.
# - example: project -> issues, project is the parent relation (issues table has a parent_id column)
#
# Two class methods must be defined when including this concern:
#
#     include RelativePositioning
#
#     # base query used for the position calculation
#     def self.relative_positioning_query_base(issue)
#       where(deleted: false)
#     end
#
#     # column that should be used in GROUP BY
#     def self.relative_positioning_parent_column
#       :project_id
#     end
#
module RelativePositioning
  extend ActiveSupport::Concern
  include ::Gitlab::RelativePositioning

  class_methods do
    def move_nulls_to_end(objects)
      move_nulls(objects, at_end: true)
    end

    def move_nulls_to_start(objects)
      move_nulls(objects, at_end: false)
    end

    private

    # @api private
    def gap_size(context, gaps:, at_end:, starting_from:)
      total_width = IDEAL_DISTANCE * gaps
      size = if at_end && starting_from + total_width >= MAX_POSITION
               (MAX_POSITION - starting_from) / gaps
             elsif !at_end && starting_from - total_width <= MIN_POSITION
               (starting_from - MIN_POSITION) / gaps
             else
               IDEAL_DISTANCE
             end

      return [size, starting_from] if size >= MIN_GAP

      terminus = context.at_position(starting_from)

      if at_end
        terminus.shift_left
        max_relative_position = terminus.relative_position
        [[(MAX_POSITION - max_relative_position) / gaps, IDEAL_DISTANCE].min, max_relative_position]
      else
        terminus.shift_right
        min_relative_position = terminus.relative_position
        [[(min_relative_position - MIN_POSITION) / gaps, IDEAL_DISTANCE].min, min_relative_position]
      end
    end

    # @api private
    # @param [Array<RelativePositioning>] objects The objects to give positions to. The relative
    #                                             order will be preserved (i.e. when this method returns,
    #                                             objects.first.relative_position < objects.last.relative_position)
    # @param [Boolean] at_end: The placement.
    #                          If `true`, then all objects with `null` positions are placed _after_
    #                          all siblings with positions. If `false`, all objects with `null`
    #                          positions are placed _before_ all siblings with positions.
    # @returns [Number] The number of moved records.
    def move_nulls(objects, at_end:)
      objects = objects.reject(&:relative_position)
      return 0 if objects.empty?

      objects.first.check_repositioning_allowed!

      number_of_gaps = objects.size # 1 to the nearest neighbour, and one between each
      representative = RelativePositioning.mover.context(objects.first)

      position = if at_end
                   representative.max_relative_position
                 else
                   representative.min_relative_position
                 end

      position ||= START_POSITION # If there are no positioned siblings, start from START_POSITION

      gap = 0
      attempts = 10 # consolidate up to 10 gaps to find enough space
      while gap < 1 && attempts > 0
        gap, position = gap_size(representative, gaps: number_of_gaps, at_end: at_end, starting_from: position)
        attempts -= 1
      end

      # Allow placing items next to each other, if we have to.
      gap = 1 if gap < MIN_GAP
      delta = at_end ? gap : -gap
      indexed = (at_end ? objects : objects.reverse).each_with_index

      lower_bound, upper_bound = at_end ? [position, MAX_POSITION] : [MIN_POSITION, position]

      representative.model_class.transaction do
        indexed.each_slice(100) do |batch|
          mapping = batch.to_h.transform_values! do |i|
            desired_pos = position + (delta * (i + 1))
            { relative_position: desired_pos.clamp(lower_bound, upper_bound) }
          end

          ::Gitlab::Database::BulkUpdate.execute([:relative_position], mapping, &:model_class)
        end
      end

      objects.size
    end
  end

  def self.mover
    ::Gitlab::RelativePositioning::Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))
  end

  # To be overriden on child classes whenever
  # blocking position updates is necessary.
  def check_repositioning_allowed!
    nil
  end

  def move_between(before, after)
    before, after = [before, after].sort_by(&:relative_position) if before && after

    RelativePositioning.mover.move(self, before, after)
  rescue NoSpaceLeft => e
    could_not_move(e)
    raise e
  end

  def move_after(before = self)
    RelativePositioning.mover.move(self, before, nil)
  rescue NoSpaceLeft => e
    could_not_move(e)
    raise e
  end

  def move_before(after = self)
    RelativePositioning.mover.move(self, nil, after)
  rescue NoSpaceLeft => e
    could_not_move(e)
    raise e
  end

  def move_to_end
    RelativePositioning.mover.move_to_end(self)
  rescue NoSpaceLeft => e
    could_not_move(e)
    self.relative_position = MAX_POSITION
  end

  def move_to_start
    RelativePositioning.mover.move_to_start(self)
  rescue NoSpaceLeft => e
    could_not_move(e)
    self.relative_position = MIN_POSITION
  end

  def next_object_by_relative_position(ignoring: nil, order: :asc)
    relation = relative_positioning_scoped_items(ignoring: ignoring).reorder(relative_position: order)

    relation = if order == :asc
                 relation.where(self.class.arel_table[:relative_position].gt(relative_position))
               else
                 relation.where(self.class.arel_table[:relative_position].lt(relative_position))
               end

    relation.first
  end

  def relative_positioning_scoped_items(ignoring: nil)
    relation = self.class.relative_positioning_query_base(self)
    relation = exclude_self(relation, excluded: ignoring) if ignoring.present?
    relation
  end

  # This method is used during rebalancing - override it to customise the update
  # logic:
  def update_relative_siblings(relation, range, delta)
    relation
      .where(relative_position: range)
      .update_all("relative_position = relative_position + #{delta}")
  end

  # This method is used to exclude the current self (or another object)
  # from a relation. Customize this if `id <> :id` is not sufficient
  def exclude_self(relation, excluded: self)
    relation.id_not_in(excluded.id)
  end

  # Override if you want to be notified of failures to move
  def could_not_move(exception); end

  # Override if the implementing class is not a simple application record, for
  # example if the record is loaded from a union.
  def reset_relative_position
    reset.relative_position
  end

  # Override if the model class needs a more complicated computation (e.g. the
  # object is a member of a union).
  def model_class
    self.class
  end
end
