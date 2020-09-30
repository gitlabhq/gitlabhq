# frozen_string_literal: true

class Projects::IncidentsController < Projects::ApplicationController
  before_action :authorize_read_issue!

  def index
  end
end
