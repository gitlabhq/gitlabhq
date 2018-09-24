# frozen_string_literal: true

module CountHelper
  def approximate_count_with_delimiters(count_data, model)
    count = count_data[model]

    raise "Missing model #{model} from count data" unless count

    number_with_delimiter(count)
  end
end
