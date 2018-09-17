# frozen_string_literal: true
module EE
  module SortingHelper
    extend ::Gitlab::Utils::Override

    override :sort_options_hash
    def sort_options_hash
      {
        sort_value_start_date => sort_title_start_date,
        sort_value_end_date   => sort_title_end_date,
        sort_value_less_weight => sort_title_less_weight,
        sort_value_more_weight => sort_title_more_weight,
        sort_value_weight      => sort_title_weight
      }.merge(super)
    end

    def sort_title_start_date
      s_('SortOptions|Planned start date')
    end

    def sort_title_end_date
      s_('SortOptions|Planned finish date')
    end

    def sort_title_less_weight
      s_('SortOptions|Less weight')
    end

    def sort_title_more_weight
      s_('SortOptions|More weight')
    end

    def sort_title_weight
      s_('SortOptions|Weight')
    end

    def sort_value_start_date
      'start_date_asc'
    end

    def sort_value_end_date
      'end_date_asc'
    end

    def sort_value_less_weight
      'weight_asc'
    end

    def sort_value_more_weight
      'weight_desc'
    end

    def sort_value_weight
      'weight'
    end
  end
end
