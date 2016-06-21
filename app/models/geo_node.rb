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
  belongs_to :oauth_application, class_name: 'Doorkeeper::Application', dependent: :destroy
  belongs_to :system_hook, dependent: :destroy

  default_values schema: 'http',
                 host: lambda { Gitlab.config.gitlab.host },
                 port: 80,
                 relative_url_root: '',
                 primary: false

  accepts_nested_attributes_for :geo_node_key, :system_hook

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)
  validates :relative_url_root, length: { minimum: 0, allow_nil: false }

  after_initialize :build_dependents
  after_save :refresh_bulk_notify_worker_status
  after_destroy :refresh_bulk_notify_worker_status
  before_validation :update_dependents_attributes

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

  def notify_projects_url
    URI.join(uri, "#{uri.path}/", "api/#{API::API.version}/geo/refresh_projects").to_s
  end

  def notify_wikis_url
    URI.join(uri, "#{uri.path}/", "api/#{API::API.version}/geo/refresh_wikis").to_s
  end

  def geo_events_url
    URI.join(uri, "#{uri.path}/", "api/#{API::API.version}/geo/receive_events").to_s
  end

  def oauth_callback_url
    Gitlab::Routing.url_helpers.oauth_geo_callback_url(url_helper_args)
  end

  def oauth_logout_url(state)
    Gitlab::Routing.url_helpers.oauth_geo_logout_url(url_helper_args.merge(state: state))
  end

  def missing_oauth_application?
    self.primary? ? false : !oauth_application.present?
  end

  private

  def url_helper_args
    if relative_url_root
      relative_url = relative_url_root.starts_with?('/') ? relative_url_root : "/#{relative_url_root}"
    end

    { protocol: schema, host: host, port: port, script_name: relative_url }
  end

  def refresh_bulk_notify_worker_status
    if Gitlab::Geo.primary?
      Gitlab::Geo.bulk_notify_job.try(:enable!)
    else
      Gitlab::Geo.bulk_notify_job.try(:disable!)
    end
  end

  def build_dependents
    self.build_geo_node_key if geo_node_key.nil?
    update_system_hook!
  end

  def update_dependents_attributes
    self.geo_node_key.title = "Geo node: #{self.url}" if self.geo_node_key

    if self.primary?
      self.oauth_application = nil
    else
      update_oauth_application!
      update_system_hook!
    end
  end

  def validate(record)
    # Prevent locking yourself out
    if record.host == Gitlab.config.gitlab.host &&
      record.port == Gitlab.config.gitlab.port &&
      record.relative_url_root == Gitlab.config.gitlab.relative_url_root && !record.primary
      record.errors[:base] << 'Current node must be the primary node or you will be locking yourself out'
    end
  end

  def update_oauth_application!
    self.build_oauth_application if oauth_application.nil?
    self.oauth_application.name = "Geo node: #{self.url}"
    self.oauth_application.redirect_uri = oauth_callback_url
  end

  def update_system_hook!
    self.build_system_hook if system_hook.nil?
    self.system_hook.token = SecureRandom.hex(20) unless self.system_hook.token.present?
    self.system_hook.url = geo_events_url if uri.present?
    self.system_hook.push_events = true
    self.system_hook.tag_push_events = true
  end
end
