# frozen_string_literal: true

class ContainerRepository < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :project

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }

  delegate :client, to: :registry

  scope :ordered, -> { order(:name) }
  scope :with_api_entity_associations, -> { preload(project: [:route, { namespace: :route }]) }
  scope :for_group_and_its_subgroups, ->(group) do
    where(project_id: Project.for_group_and_its_subgroups(group).with_container_registry.select(:id))
  end

  # rubocop: disable CodeReuse/ServiceClass
  def registry
    @registry ||= begin
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(path)

      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port

      ContainerRegistry::Registry.new(url, token: token, path: host_port)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def path
    @path ||= [project.full_path, name]
      .select(&:present?).join('/').downcase
  end

  def location
    File.join(registry.path, path)
  end

  def tag(tag)
    ContainerRegistry::Tag.new(self, tag)
  end

  def manifest
    @manifest ||= client.repository_tags(path)
  end

  def tags
    return [] unless manifest && manifest['tags']

    strong_memoize(:tags) do
      manifest['tags'].sort.map do |tag|
        ContainerRegistry::Tag.new(self, tag)
      end
    end
  end

  def blob(config)
    ContainerRegistry::Blob.new(self, config)
  end

  def has_tags?
    tags.any?
  end

  def root_repository?
    name.empty?
  end

  def delete_tags!
    return unless has_tags?

    digests = tags.map { |tag| tag.digest }.compact.to_set

    digests.map(&method(:delete_tag_by_digest)).all?
  end

  def delete_tag_by_digest(digest)
    client.delete_repository_tag(self.path, digest)
  end

  def self.build_from_path(path)
    self.new(project: path.repository_project,
             name: path.repository_name)
  end

  def self.create_from_path!(path)
    build_from_path(path).tap(&:save!)
  end

  def self.build_root_repository(project)
    self.new(project: project, name: '')
  end

  def self.find_by_path!(path)
    self.find_by!(project: path.repository_project,
                  name: path.repository_name)
  end
end

ContainerRepository.prepend_if_ee('EE::ContainerRepository')
