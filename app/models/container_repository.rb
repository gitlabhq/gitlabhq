class ContainerRepository < ActiveRecord::Base
  belongs_to :project
  delegate :client, to: :registry
  validates :manifest, presence: true
  validates :name, presence: true
  before_destroy :delete_tags

  def registry
    @registry ||= begin
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(path)

      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port

      ContainerRegistry::Registry.new(url, token: token, path: host_port)
    end
  end

  def path
    @path ||= "#{project.full_path}/#{name}"
  end

  def tag(tag)
    ContainerRegistry::Tag.new(self, tag)
  end

  def manifest
    @manifest ||= client.repository_tags(self.path)
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
      client.delete_repository_tag(self.path, digest)
    end
  end

  def self.project_from_path(repository_path)
    return unless repository_path.include?('/')

    ##
    # Projects are always located inside a namespace, so we can remove
    # the last node, and see if project with that path exists.
    #
    truncated_path = repository_path.slice(0...repository_path.rindex('/'))

    ##
    # We still make it possible to search projects by a full image path
    # in order to maintain backwards compatibility.
    #
    Project.find_by_full_path(truncated_path) ||
      Project.find_by_full_path(repository_path)
  end
end
