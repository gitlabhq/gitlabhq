class GlobalLabel
  attr_accessor :title, :labels
  alias_attribute :name, :title

  delegate :color, :text_color, :description, to: :@first_label

  def for_display
    @first_label
  end

  def self.build_collection(labels)
    labels = labels.group_by(&:title)

    labels.map do |title, labels|
      new(title, labels)
    end
  end

  def initialize(title, labels)
    @title = title
    @labels = labels
    @first_label = labels.find { |lbl| lbl.description.present? } || labels.first
  end
end
