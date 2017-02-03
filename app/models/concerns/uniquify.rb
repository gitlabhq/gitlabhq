class Uniquify
  # Return a version of the given 'base' string that is unique
  # by appending a counter to it. Uniqueness is determined by
  # repeated calls to `exists_fn`.
  #
  # If `base` is a function/proc, we expect that calling it with a
  # candidate counter returns a string to test/return.
  def string(base, exists_fn)
    @counter = nil

    if base.respond_to?(:call)
      increment_counter! while exists_fn[base.call(@counter)]
      base.call(@counter)
    else
      increment_counter! while exists_fn["#{base}#{@counter}"]
      "#{base}#{@counter}"
    end
  end

  private

  def increment_counter!
    @counter = @counter ? @counter.next : 1
  end
end
