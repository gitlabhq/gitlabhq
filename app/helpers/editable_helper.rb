module EditableHelper
  def is_edited?(object)
    !object.last_edited_at.blank? && object.last_edited_at != object.created_at
  end
end
