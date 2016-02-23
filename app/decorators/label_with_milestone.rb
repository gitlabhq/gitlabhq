class LabelWithMilestone
  attr_reader :milestone

  def initialize(label, milestone)
    @label, @milestone = label, milestone
  end

  def method_missing(meth, *args)
    if @label.respond_to?(meth)
      @label.send(meth, *args)
    else
      super
    end
  end

  def respond_to?(meth)
    @label.respond_to?(meth)
  end
end
