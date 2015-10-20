class GroupLabel
  attr_accessor :title, :labels
  alias_attribute :name, :title

  def initialize(title, labels)
    @title = title
    @labels = labels
  end
end
