# frozen_string_literal: true

module NumbersHelper
  def limited_counter_with_delimiter(resource, **options)
    limit = options.fetch(:limit, 1000).to_i
    count = resource.page.total_count_with_limit(:all, limit: limit)

    if count > limit
      "#{number_with_delimiter(count - 1, options)}+"
    elsif count == 0
      options.fetch(:include_zero, true) ? "0" : nil
    else
      number_with_delimiter(count, options)
    end
  end
end
