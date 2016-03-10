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
  belongs_to :geo_node_key, dependent: :destroy

  default_values schema: 'http',
                 host: lambda { Gitlab.config.gitlab.host },
                 port: 80,
                 relative_url_root: '',
                 primary: false

  accepts_nested_attributes_for :geo_node_key

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'primary node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)
  validates :relative_url_root, length: { minimum: 0, allow_nil: false }

  after_initialize :check_geo_node_key
  after_save :refresh_bulk_notify_worker_status
  after_destroy :refresh_bulk_notify_worker_status
  before_validation :change_geo_node_key_title

  def uri
    if relative_url_root
      relative_url = relative_url_root.starts_with?('/') ? relative_url_root : "/#{relative_url_root}"
    end

    URI.parse(URI::Generic.build(scheme: schema, host: host, port: port, path: relative_url).normalize.to_s)
  end

  def url
    uri.to_s
  end

  def url=(new_url)
    new_uri = URI.parse(new_url)
    self.schema = new_uri.scheme
    self.host = new_uri.host
    self.port = new_uri.port
    self.relative_url_root = new_uri.path != '/' ? new_uri.path : ''
  end

  def notify_url
    URI.join(uri, "#{uri.path}/", "api/#{API::API.version}/geo/refresh_projects").to_s
  end

  private

  def refresh_bulk_notify_worker_status
    if Gitlab::Geo.primary?
      Gitlab::Geo.bulk_notify_job.try(:enable!)
    else
      Gitlab::Geo.bulk_notify_job.try(:disable!)
    end
  end

  def check_geo_node_key
    self.build_geo_node_key if geo_node_key.nil?
  end

  def change_geo_node_key_title
    self.geo_node_key.title = "Geo node: #{self.url}" if self.geo_node_key
  end

  def validate(record)
    # Prevent locking yourself out
    if record.host == Gitlab.config.gitlab.host &&
       record.port == Gitlab.config.gitlab.port &&
       record.relative_url_root == Gitlab.config.gitlab.relative_url_root && !record.primary
      record.errors[:base] << 'Current node must be the primary node or you will be locking yourself out'
    end
  end
end
