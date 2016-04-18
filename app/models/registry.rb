require 'net/http'

class Registry
  attr_accessor :path_with_namespace, :project

  def initialize(path_with_namespace, project)
    @path_with_namespace = path_with_namespace
    @project = project
  end

  def tags
    @tags ||= client.tags(path_with_namespace)
  end

  def tag(reference)
    return @tag[reference] if defined?(@tag[reference])
    @tag ||= {}
    @tag[reference] ||= client.tag(path_with_namespace, reference)
  end

  def tag_digest(reference)
    return @tag_digest[reference] if defined?(@tag_digest[reference])
    @tag_digest ||= {}
    @tag_digest[reference] ||= client.tag_digest(path_with_namespace, reference)
  end

  def destroy_tag(reference)
    client.delete_tag(path_with_namespace, reference)
  end

  def blob_size(blob)
    return @blob_size[blob] if defined?(@blob_size[blob])
    @blob_size ||= {}
    @blob_size[blob] ||= client.blob_size(path_with_namespace, blob)
  end

  private

  def client
    @client ||= RegistryClient.new(Gitlab.config.registry.api_url)
  end
end
