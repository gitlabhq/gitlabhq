module GraphHelper
  def join_with_space(ary)
    ary.collect{|r|r.name}.join(" ") unless ary.nil?
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end
end
