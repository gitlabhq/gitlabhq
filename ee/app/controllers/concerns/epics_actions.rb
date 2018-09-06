# frozen_string_literal: true
module EpicsActions
  private

  def finder_type
    EpicsFinder
  end

  def collection_type
    @collection_type ||= 'Epic'
  end

  def default_sort_order
    sort_value_end_date
  end

  def update_cookie_value(value)
    case value
    when 'start_date_asc'  then sort_value_start_date
    when 'end_date_asc'    then sort_value_end_date
    else
      super(value)
    end
  end
end
