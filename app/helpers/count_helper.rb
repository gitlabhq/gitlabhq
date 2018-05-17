module CountHelper
  def approximate_count_with_delimiters(model)
    number_with_delimiter(Gitlab::Database::Count.approximate_count(model))
  end
end
