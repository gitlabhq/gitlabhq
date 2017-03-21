class ContainerImage < ActiveRecord::Base
  include Routable

  belongs_to :project

  delegate :container_registry, :container_registry_allowed_paths,
    :container_registry_path_with_namespace, to: :project

  delegate :client, to: :container_registry

  validates :manifest, presence: true

  before_destroy :delete_tags

  before_validation :update_token, on: :create
  def update_token
    paths = container_registry_allowed_paths << name_with_namespace
    token = Auth::ContainerRegistryAuthenticationService.full_access_token(paths)
    client.update_token(token)
  end

  def parent
    project
  end

  def parent_changed?
    project_id_changed?
  end

 # def path
 #   [container_registry.path, name_with_namespace].compact.join('/')
 # end

  def name_with_namespace
    [container_registry_path_with_namespace, name].reject(&:blank?).join('/')
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

    digests = tags.map {|tag| tag.digest }.to_set
    digests.all? do |digest|
      client.delete_repository_tag(name_with_namespace, digest)
    end
  end

  # rubocop:disable RedundantReturn

  def self.split_namespace(full_path)
    image_name = full_path.split('/').last
    namespace = full_path.gsub(/(.*)(#{Regexp.escape('/' + image_name)})/, '\1')
    if namespace.count('/') < 1
      namespace, image_name = full_path, ""
    end
    return namespace, image_name
  end
end
