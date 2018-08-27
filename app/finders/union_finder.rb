class UnionFinder
  # rubocop: disable CodeReuse/ActiveRecord
  def find_union(segments, klass)
    if segments.length > 1
      union = Gitlab::SQL::Union.new(segments.map { |s| s.select(:id) })

      klass.where("#{klass.table_name}.id IN (#{union.to_sql})")
    else
      segments.first
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
