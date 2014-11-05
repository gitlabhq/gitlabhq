class Projects::BaseTreeController < Projects::ApplicationController
  include ExtractsPath

  before_filter :authorize_download_code!
  before_filter :require_non_empty_project
end

