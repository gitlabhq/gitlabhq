# frozen_string_literal: true

module NumbersHelper
  WORDS = %w[zero one two three four five six seven eight nine].freeze

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

  def number_in_words(num)
    raise ArgumentError, _('Input must be an integer between 0 and 9') unless num.between?(0, 9)

    WORDS[num]
  end
end
