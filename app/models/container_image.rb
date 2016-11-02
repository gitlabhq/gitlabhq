class ContainerImage < ActiveRecord::Base
  belongs_to :container_images_repository

  delegate :registry, :registry_path_with_namespace, :client, to: :container_images_repository

  validates :manifest, presence: true

  before_validation :update_token, on: :create
  def update_token
    paths = container_images_repository.allowed_paths << name_with_namespace
    token = Auth::ContainerRegistryAuthenticationService.full_access_token(paths)
    client.update_token(token)
  end

  def path
    [registry.path, name_with_namespace].compact.join('/')
  end

  def name_with_namespace
    [registry_path_with_namespace, name].compact.join('/')
  end

  def tag(tag)
    ContainerRegistry::Tag.new(self, tag)
  end

  def manifest
    @manifest ||= client.repository_tags(name_with_namespace)
  end

  def tags
    return @tags if defined?(@tags)
    return [] unless manifest && manifest['tags']

    @tags = manifest['tags'].map do |tag|
      ContainerRegistry::Tag.new(self, tag)
    end
  end

  def blob(config)
    ContainerRegistry::Blob.new(self, config)
  end

  def delete_tags
    return unless tags

    tags.all?(&:delete)
  end

  def self.split_namespace(full_path)
    image_name = full_path.split('/').last
    namespace = full_path.gsub(/(.*)(#{Regexp.escape('/' + image_name)})/, '\1')
    if namespace.count('/') < 1
      namespace, image_name = full_path, ""
    end
    return namespace, image_name
  end
end
