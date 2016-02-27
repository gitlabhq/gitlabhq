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

  default_values schema: 'http',
                 host: lambda { Gitlab.config.gitlab.host },
                 port: 80,
                 relative_url_root: '',
                 primary: false

  accepts_nested_attributes_for :geo_node_key

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'primary node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)

  after_save :refresh_bulk_notify_worker_status
  after_destroy :refresh_bulk_notify_worker_status
  after_destroy :destroy_orphaned_geo_node_key

  def uri
    if relative_url_root
      relative_url = relative_url_root.starts_with?('/') ? relative_url_root : relative_url_root.prepend('/')
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
    self.relative_url_root = new_uri.path if new_uri.path != '/'
  end

  def notify_url
    URI::join(uri, "#{uri.path}/", 'api/geo/refresh_projects').to_s
  end

  private

  def destroy_orphaned_geo_node_key
    return unless self.geo_node_key.destroyed_when_orphaned? && self.geo_node_key.orphaned?

    self.geo_node_key.destroy
  end

  def refresh_bulk_notify_worker_status
    Gitlab::Geo.primary? ? Gitlab::Geo.bulk_notify_job.try(:enable!) : Gitlab::Geo.bulk_notify_job.try(:disable!)
  end
end
