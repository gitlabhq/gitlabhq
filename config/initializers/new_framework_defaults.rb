# Remove this `if` condition when upgraded to rails 5.0.
# The body must be kept.
if Gitlab.rails5?
  # Be sure to restart your server when you modify this file.
  #
  # This file contains migration options to ease your Rails 5.0 upgrade.
  #
  # Once upgraded flip defaults one by one to migrate to the new default.
  #
  # Read the Guide for Upgrading Ruby on Rails for more info on each option.

  Rails.application.config.action_controller.raise_on_unfiltered_parameters = true

  # Enable per-form CSRF tokens. Previous versions had false.
  Rails.application.config.action_controller.per_form_csrf_tokens = false

  # Enable origin-checking CSRF mitigation. Previous versions had false.
  Rails.application.config.action_controller.forgery_protection_origin_check = false

  # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
  # Previous versions had false.
  ActiveSupport.to_time_preserves_timezone = false

  # Require `belongs_to` associations by default. Previous versions had false.
  Rails.application.config.active_record.belongs_to_required_by_default = false

  # Do not halt callback chains when a callback returns false. Previous versions had true.
  ActiveSupport.halt_callback_chains_on_return_false = true
end
