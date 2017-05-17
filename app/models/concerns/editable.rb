module Editable
  extend ActiveSupport::Concern

  def is_edited?
    last_edited_at.present? && last_edited_at != created_at
  end
end
