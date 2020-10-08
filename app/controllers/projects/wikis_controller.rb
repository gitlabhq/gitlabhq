# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions

  alias_method :container, :project

  feature_category :wiki

  def git_access
  end
end
