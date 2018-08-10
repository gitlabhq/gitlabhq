# frozen_string_literal: true
module EE
  module SortingHelper
    extend ::Gitlab::Utils::Override

    override :sort_options_hash
    def sort_options_hash
      {
        sort_value_start_date => sort_title_start_date,
        sort_value_end_date   => sort_title_end_date
      }.merge(super)
    end

    def sort_title_start_date
      s_('SortOptions|Planned start date')
    end

    def sort_title_end_date
      s_('SortOptions|Planned finish date')
    end

    def sort_value_start_date
      'start_date_asc'
    end

    def sort_value_end_date
      'end_date_asc'
    end
  end
end
