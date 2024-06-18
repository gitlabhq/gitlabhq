# frozen_string_literal: true

module Kaminari
  # Active Record specific page scope methods implementations
  module ActiveRecordRelationMethodsWithLimit
    MAX_COUNT_LIMIT = 10_000

    # This is a modified version of
    # https://github.com/kaminari/kaminari/blob/c5186f5d9b7f23299d115408e62047447fd3189d/kaminari-activerecord/lib/kaminari/activerecord/active_record_relation_methods.rb#L17-L41
    # that limit the COUNT query to a configurable value to avoid query timeouts.
    # The default limit value is 10,000 records
    # rubocop: disable Gitlab/ModuleWithInstanceVariables
    def total_count_with_limit(column_name = :all, options = {}) # :nodoc:
      return @total_count if defined?(@total_count) && @total_count

      # There are some cases that total count can be deduced from loaded records
      if loaded?
        # Total count has to be 0 if loaded records are 0
        return @total_count = 0 if (current_page == 1) && @records.empty?
        # Total count is calculable at the last page
        return @total_count = ((current_page - 1) * limit_value) + @records.length if @records.any? && (@records.length < limit_value)
      end

      limit = options.fetch(:limit, MAX_COUNT_LIMIT).to_i
      # #count overrides the #select which could include generated columns referenced in #order, so skip #order here, where it's irrelevant to the result anyway
      c = except(:offset, :limit, :order)
      # Remove includes only if they are irrelevant
      c = c.except(:includes) unless references_eager_loaded_tables?
      # .group returns an OrderedHash that responds to #count
      # The following line was modified from `c = c.count(:all)`
      c = c.limit(limit + 1).count(column_name)
      @total_count =
        if c.is_a?(Hash) || c.is_a?(ActiveSupport::OrderedHash)
          c.count
        elsif c.respond_to? :count
          c.count(column_name)
        else
          c
        end
    end
    # rubocop: enable Gitlab/ModuleWithInstanceVariables

    Kaminari::ActiveRecordRelationMethods.prepend(self)
  end
end
