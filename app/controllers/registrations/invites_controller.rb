# frozen_string_literal: true

module Registrations
  class InvitesController < RegistrationsController
    layout 'simple_registration'

    before_action :check_if_gl_com_or_dev
  end
end
