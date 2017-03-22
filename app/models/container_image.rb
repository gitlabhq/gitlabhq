class ContainerImage < ActiveRecord::Base
  include Routable

  belongs_to :project

  delegate :container_registry,  to: :project
  delegate :client, to: :container_registry

  validates :manifest, presence: true

  before_destroy :delete_tags

  def registry
    # TODO, container registry with image access level
    token = Auth::ContainerRegistryAuthenticationService.image_token(self)
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
