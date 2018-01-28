module NumbersHelper
  def limited_counter_with_delimiter(resource, **options)
    limit = options.fetch(:limit, 1000).to_i
    count = resource.limit(limit + 1).count(:all)
    if count > limit
      number_with_delimiter(count - 1, options) + '+'
    else
      number_with_delimiter(count, options)
    end
  end
end
