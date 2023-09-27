# frozen_string_literal: true

# GitLab lightweight base action controller
#
# This class should be limited to content that
# is desired/required for *all* controllers in
# GitLab.
#
# Most controllers inherit from `ApplicationController`.
# Some controllers don't want or need all of that
# logic and instead inherit from `ActionController::Base`.
# This makes it difficult to set security headers and
# handle other critical logic across *all* controllers.
#
# Between this controller and `ApplicationController`
# no controller should ever inherit directly from
# `ActionController::Base`
#
# rubocop:disable Rails/ApplicationController
# rubocop:disable Gitlab/NamespacedClass
class BaseActionController < ActionController::Base
  before_action :security_headers

  private

  def security_headers
    headers['Cross-Origin-Opener-Policy'] = 'same-origin' if ::Feature.enabled?(:coop_header)
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
