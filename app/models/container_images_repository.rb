class ContainerImagesRepository < ActiveRecord::Base

  belongs_to :project

  has_many :container_images, dependent: :destroy

  delegate :client, to: :registry

  def registry_path_with_namespace
    project.path_with_namespace.downcase
  end

  def allowed_paths
    @allowed_paths ||= [registry_path_with_namespace] +
      container_images.map { |i| i.name_with_namespace }
  end

  def registry
    @registry ||= begin
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(allowed_paths)
      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port
      ContainerRegistry::Registry.new(url, token: token, path: host_port)
    end
  end
end
