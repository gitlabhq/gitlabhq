module PublicHelper
  def public_head_title
    if current_controller?(:projects)
      "Public Projects"
    elsif current_controller?(:users)
      "Users"
    else
      raise "Unknown controller."
    end
  end
end
