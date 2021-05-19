# frozen_string_literal: true

# == EnforcesTwoFactorAuthentication
#
# Controller concern to enforce two-factor authentication requirements
#
# Upon inclusion, adds `check_two_factor_requirement` as a before_action,
# and makes `two_factor_grace_period_expired?` and `two_factor_skippable?`
# available as view helpers.
module EnforcesTwoFactorAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :check_two_factor_requirement, except: [:route_not_found]

    # to include this in controllers inheriting from `ActionController::Metal`
    # we need to add this block
    if respond_to?(:helper_method)
      helper_method :two_factor_grace_period_expired?, :two_factor_skippable?
    end
  end

  def check_two_factor_requirement
    return unless respond_to?(:current_user)

    if two_factor_authentication_required? && current_user_requires_two_factor?
      redirect_to profile_two_factor_auth_path
    end
  end

  def two_factor_authentication_required?
    two_factor_verifier.two_factor_authentication_required?
  end

  def current_user_requires_two_factor?
    two_factor_verifier.current_user_needs_to_setup_two_factor? && !skip_two_factor?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def two_factor_authentication_reason(global: -> {}, group: -> {})
    if two_factor_authentication_required?
      if Gitlab::CurrentSettings.require_two_factor_authentication?
        global.call
      else
        groups = current_user.source_groups_of_two_factor_authentication_requirement.reorder(name: :asc)
        group.call(groups)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def two_factor_grace_period
    two_factor_verifier.two_factor_grace_period
  end

  def two_factor_grace_period_expired?
    two_factor_verifier.two_factor_grace_period_expired?
  end

  def two_factor_skippable?
    two_factor_authentication_required? &&
      !current_user.two_factor_enabled? &&
      !two_factor_grace_period_expired?
  end

  def skip_two_factor?
    session[:skip_two_factor] && session[:skip_two_factor] > Time.current
  end

  def two_factor_verifier
    @two_factor_verifier ||= Gitlab::Auth::TwoFactorAuthVerifier.new(current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end

EnforcesTwoFactorAuthentication.prepend_mod_with('EnforcesTwoFactorAuthentication')
