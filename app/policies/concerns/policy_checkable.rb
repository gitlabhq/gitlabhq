# frozen_string_literal: true

# Include this module if we want to pass something else than the user to
# check policies. This defines several methods which the policy checker
# would call and check.
module PolicyCheckable
  extend ActiveSupport::Concern

  def blocked?
    false
  end

  def admin?
    false
  end

  def external?
    false
  end

  def internal?
    false
  end

  def access_locked?
    false
  end

  def required_terms_not_accepted?
    false
  end

  def can_create_group
    false
  end
end
