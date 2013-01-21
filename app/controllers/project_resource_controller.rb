class ProjectResourceController < ApplicationController
  before_filter :project
  before_filter :repository
end
