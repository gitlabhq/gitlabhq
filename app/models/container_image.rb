class ContainerImage < ActiveRecord::Base
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

  def self.from_path(full_path)
    return unless full_path.include?('/')

    path = full_path[0...full_path.rindex('/')]
    name = full_path[full_path.rindex('/')+1..-1]
    project = Project.find_by_full_path(path)

    self.new(name: name, path: path, project: project)
  end
end
