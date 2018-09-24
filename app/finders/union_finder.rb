# frozen_string_literal: true

class UnionFinder
  def find_union(segments, klass)
    unless klass < FromUnion
      raise TypeError, "#{klass.inspect} must include the FromUnion module"
    end

    if segments.length > 1
      klass.from_union(segments)
    else
      segments.first
    end
  end
end
