# == Schema Information
#
# Table name: geo_nodes
#
#  id                :integer          not null, primary key
#  schema            :string
#  host              :string
#  port              :integer
#  relative_url_root :string
#  primary           :boolean
#

class GeoNode < ActiveRecord::Base
  belongs_to :geo_node_key

  default_value_for :schema, 'http'
  default_value_for :port, 80
  default_value_for :relative_url_root, ''
  default_value_for :primary, false

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'primary node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)

  def uri
    relative_url = relative_url_root[0] == '/' ? relative_url_root[1..-1] : relative_url_root
    URI.parse("#{schema}://#{host}:#{port}/#{relative_url}")
  end

  def url
    uri.to_s
  end

  def url=(new_url)
    new_uri = URI.parse(new_url)
    self.schema = new_uri.scheme
    self.host = new_uri.host
    self.port = new_uri.port
    self.relative_url_root = new_uri.path
  end

  def notify_url
    URI::join(uri, "#{uri.path}/", 'api/geo/refresh_projects').to_s
  end
end
