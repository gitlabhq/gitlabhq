module Projects
  module Registry
    class ApplicationController < Projects::ApplicationController
      layout 'project'

      before_action :verify_registry_enabled
      before_action :authorize_read_container_image!
    end
  end
end
