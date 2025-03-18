# frozen_string_literal: true

module Editable
  extend ActiveSupport::Concern

  def edited?
    last_edited_at.present? && last_edited_at != created_at
  end

  def last_edited_by
    return unless edited?

    super || Users::Internal.ghost
  end
end
