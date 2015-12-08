class GlobalLabel
  attr_accessor :title, :labels
  alias_attribute :name, :title

  def self.build_collection(labels)
    labels = labels.group_by(&:title)

    labels.map do |title, label|
      new(title, label)
    end
  end

  def initialize(title, labels)
    @title = title
    @labels = labels
  end
end
