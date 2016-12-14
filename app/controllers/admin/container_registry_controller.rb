class Admin::ContainerRegistryController < Admin::ApplicationController
  def show
    @access_token = container_registry_access_token
  end

  private

  def container_registry_access_token
    current_application_settings.container_registry_access_token
  end
end
