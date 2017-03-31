module Projects
  module Registry
    class TagsController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]
    end
  end
end
