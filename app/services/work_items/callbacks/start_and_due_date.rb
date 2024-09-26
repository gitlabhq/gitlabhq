# frozen_string_literal: true

module WorkItems
  module Callbacks
    class StartAndDueDate < Base
      include ::Gitlab::Utils::StrongMemoize

      def before_update
        assign_attributes
      end

      def before_create
        assign_attributes
      end

      private

      def assign_attributes
        return unless has_permission?(:set_work_item_metadata)
        return if dates_source_attributes.blank?
        return if work_item.invalid?

        # Although we have the database trigger to ensure the sync between the
        # work_items_dates_sources[start_date, due_date] and issues[start_date, due_date]
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157993
        # for now, here we also assign the values directly to work_item to avoid
        # having to reload this object after the Update service is finished.
        #
        # This is important for places like the GraphQL where we use the same
        # instance in memory for all the changes and then use the same object
        # to build the GraphQL response
        work_item.assign_attributes(dates_source_attributes.slice(:start_date, :due_date))
        (work_item.dates_source || work_item.build_dates_source).then do |dates_source|
          dates_source.assign_attributes(dates_source_attributes)
        end
      end

      def dates_source_attributes
        return empty_dates_source if excluded_in_new_type?

        build_dates_source_attributes
      end
      strong_memoize_attr :dates_source_attributes

      # overridden in EE
      def build_dates_source_attributes
        attributes = { due_date_is_fixed: true, start_date_is_fixed: true }

        if params.key?(:start_date)
          attributes[:start_date] = params[:start_date]
          attributes[:start_date_fixed] = params[:start_date]
        end

        if params.key?(:due_date)
          attributes[:due_date] = params[:due_date]
          attributes[:due_date_fixed] = params[:due_date]
        end

        attributes
      end

      def empty_dates_source
        {
          due_date: nil,
          due_date_fixed: nil,
          due_date_is_fixed: true,
          start_date: nil,
          start_date_fixed: nil,
          start_date_is_fixed: true
        }
      end
    end
  end
end
WorkItems::Callbacks::StartAndDueDate.prepend_mod
