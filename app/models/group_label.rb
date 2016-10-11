class GroupLabel < Label
  belongs_to :group

  validates :group, presence: true

  ##
  # Returns the String necessary to reference this GroupLabel in Markdown
  #
  # format - Symbol format to use (default: :id, optional: :name)
  #
  # Examples:
  #
  #   GroupLabel.first.to_reference                # => "~1"
  #   GroupLabel.first.to_reference(format: :name) # => "~\"bug\""
  #
  # Returns a String
  #
  def to_reference(source_project = nil, target_project = nil, format: :id)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if cross_project_reference?(source_project, target_project)
      source_project.to_reference + reference
    else
      reference
    end
  end

  private

  def cross_project_reference?(source_project, target_project)
    source_project && target_project && source_project != target_project
  end
end
