module Editable
  extend ActiveSupport::Concern

  def edited?
    last_edited_at.present? && last_edited_at != created_at
  end

  def last_edited_by
    super || User.ghost
  end
end
