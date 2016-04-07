require 'HTTParty'

class RegistryClient
  attr_accessor :uri

  def initialize(uri)
    @uri = uri
  end

  def tags(name)
    response = HTTParty.get("#{uri}/v2/#{name}/tags/list")
    response.parsed_response['tags']
  end

  def tag(name, reference)
    response = HTTParty.get("#{uri}/v2/#{name}/manifests/#{reference}")
    JSON.parse(response)
  end

  def delete_tag(name, reference)
    HTTParty.delete("#{uri}/v2/#{name}/manifests/#{reference}")
  end

  def blob_size(name, digest)
    response = HTTParty.head("#{uri}/v2/#{name}/blobs/#{digest}")
    response.headers.content_length
  end

  def delete_blob(name, digest)
    HTTParty.delete("#{uri}/v2/#{name}/blobs/#{digest}")
  end
end
