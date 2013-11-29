class Projects::BaseTreeController < Projects::ApplicationController
  include ExtractsPath

  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
end

