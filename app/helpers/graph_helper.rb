module GraphHelper
  def join_with_space(ary)
    ary.collect{|r|r.name}.join(" ") unless ary.nil?
  end
end
