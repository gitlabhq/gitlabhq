# frozen_string_literal: true

module ForcedEmailConfirmation
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_confirmation_period_expiry_check
  end

  def force_confirm(args = {})
    self.skip_confirmation_period_expiry_check = true
    confirm(args)
  ensure
    self.skip_confirmation_period_expiry_check = nil
  end

  protected

  # Override, from Devise::Models::Confirmable
  # Link: https://github.com/heartcombo/devise/blob/main/lib/devise/models/confirmable.rb
  def confirmation_period_expired?
    return false if skip_confirmation_period_expiry_check

    super
  end
end
