# frozen_string_literal: true

class UnionFinder
  def find_union(segments, klass)
    raise TypeError, "#{klass.inspect} must include the FromUnion module" unless klass < FromUnion

    if segments.length > 1
      klass.from_union(segments)
    else
      segments.first
    end
  end
end
