# frozen_string_literal: true

class Profiles::ActiveSessionsController < Profiles::ApplicationController
  def index
    @sessions = ActiveSession.list(current_user).reject(&:is_impersonated)
  end
end
