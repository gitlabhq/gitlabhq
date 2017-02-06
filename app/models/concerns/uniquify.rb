class Uniquify
  # Return a version of the given 'base' string that is unique
  # by appending a counter to it. Uniqueness is determined by
  # repeated calls to `exists_fn`.
  #
  # If `base` is a function/proc, we expect that calling it with a
  # candidate counter returns a string to test/return.
  def string(base, exists_fn)
    @base = base
    @counter = nil

    increment_counter! while exists_fn[base_string]
    base_string
  end

  private

  def base_string
    if @base.respond_to?(:call)
      @base.call(@counter)
    else
      "#{@base}#{@counter}"
    end
  end

  def increment_counter!
    @counter = @counter ? @counter.next : 1
  end
end
