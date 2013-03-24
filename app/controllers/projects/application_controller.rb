class Projects::ApplicationController < ApplicationController
  before_filter :project
  before_filter :repository
end
