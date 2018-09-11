# frozen_string_literal: true

module StorageHelper
  def storage_counter(size_in_bytes)
    precision = size_in_bytes < 1.megabyte ? 0 : 1

    number_to_human_size(size_in_bytes, delimiter: ',', precision: precision, significant: false)
  end
end
