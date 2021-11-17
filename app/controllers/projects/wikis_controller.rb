# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions

  urgency :low

  alias_method :container, :project

  feature_category :wiki
end
