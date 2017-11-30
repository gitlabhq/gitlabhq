module MilestoneArray
  class << self
    def sort(array, sort_method)
      case sort_method
      when 'due_date_asc'
        sort_asc_nulls_last(array, 'due_date')
      when 'due_date_desc'
        sort_desc_nulls_last(array, 'due_date')
      when 'start_date_asc'
        sort_asc_nulls_last(array, 'start_date')
      when 'start_date_desc'
        sort_desc_nulls_last(array, 'start_date')
      when 'name_asc'
        sort_asc(array, 'title')
      when 'name_desc'
        sort_asc(array, 'title').reverse
      else
        array
      end
    end

    private

    def sort_asc_nulls_last(array, attribute)
      attribute = attribute.to_sym

      array.select(&attribute).sort_by(&attribute) + array.reject(&attribute)
    end

    def sort_desc_nulls_last(array, attribute)
      attribute = attribute.to_sym

      array.select(&attribute).sort_by(&attribute).reverse + array.reject(&attribute)
    end

    def sort_asc(array, attribute)
      array.sort_by(&attribute.to_sym)
    end
  end
end
