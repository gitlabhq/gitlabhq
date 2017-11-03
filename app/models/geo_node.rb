class GeoNode < ActiveRecord::Base
  include Presentable

  belongs_to :geo_node_key, inverse_of: :geo_node, dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
  belongs_to :oauth_application, class_name: 'Doorkeeper::Application', dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

  has_many :geo_node_namespace_links
  has_many :namespaces, through: :geo_node_namespace_links

  default_values schema: lambda { Gitlab.config.gitlab.protocol },
                 host: lambda { Gitlab.config.gitlab.host },
                 port: lambda { Gitlab.config.gitlab.port },
                 relative_url_root: lambda { Gitlab.config.gitlab.relative_url_root },
                 primary: false,
                 clone_protocol: 'http'

  accepts_nested_attributes_for :geo_node_key

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)
  validates :relative_url_root, length: { minimum: 0, allow_nil: false }
  validates :access_key, presence: true
  validates :encrypted_secret_access_key, presence: true
  validates :clone_protocol, presence: true, inclusion: %w(ssh http)

  validates :geo_node_key, presence: true, if: :uses_ssh_key?
  validate :check_not_adding_primary_as_secondary, if: :secondary?

  after_initialize :build_dependents
  after_save :expire_cache!
  after_destroy :expire_cache!
  before_validation :update_dependents_attributes

  before_validation :ensure_access_keys!

  attr_encrypted :secret_access_key,
                 key: Gitlab::Application.secrets.db_key_base,
                 algorithm: 'aes-256-gcm',
                 mode: :per_attribute_iv,
                 encode: true

  def current?
    Gitlab::Geo.current_node == self
  end

  def secondary?
    !primary
  end

  def uses_ssh_key?
    secondary? && clone_protocol == 'ssh'
  end

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

  def geo_transfers_url(file_type, file_id)
    geo_api_url("transfers/#{file_type}/#{file_id}")
  end

  def status_url
    geo_api_url('status')
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

  def update_clone_url!
    update_clone_url

    # Update with update_column to prevent calling callbacks as this method will
    # be called in an initializer and we don't want other callbacks
    # to mess with uninitialized dependencies.
    if clone_url_prefix_changed?
      Rails.logger.info "Geo: modified clone_url_prefix to #{clone_url_prefix}"
      update_column(:clone_url_prefix, clone_url_prefix)
    end
  end

  def projects_include?(project_id)
    return true if restricted_project_ids.nil?

    restricted_project_ids.include?(project_id)
  end

  def restricted_project_ids
    return unless namespaces.presence

    relations = namespaces.map { |namespace| namespace.all_projects.select(:id) }

    Project.unscoped
       .from("(#{Gitlab::SQL::Union.new(relations).to_sql}) #{Project.table_name}")
       .pluck(:id)
  end

  def lfs_objects
    relation =
      if restricted_project_ids
        LfsObject.joins(:projects).where(projects: { id: restricted_project_ids })
      else
        LfsObject.all
      end

    relation.with_files_stored_locally
  end

  def projects
    if restricted_project_ids
      Project.where(id: restricted_project_ids)
    else
      Project.all
    end
  end

  def project_registries
    if restricted_project_ids
      Geo::ProjectRegistry.where(project_id: restricted_project_ids)
    else
      Geo::ProjectRegistry.all
    end
  end

  # These are projects that meet the project restriction but haven't yet been
  # synced (i.e., do not yet have a project registry entry).
  #
  # This query requires data from two different databases, and unavoidably
  # plucks a list of project IDs from one into the other. This will not scale
  # well with the number of synchronized projects - the query will increase
  # linearly in size - so this should be replaced with postgres_fdw ASAP.
  def unsynced_projects
    registry_project_ids = project_registries.pluck(:project_id)
    return projects if registry_project_ids.empty?

    joined_relation = projects.joins(<<~SQL)
      LEFT OUTER JOIN
      (VALUES #{registry_project_ids.map { |id| "(#{id}, 't')" }.join(',')})
      project_registry(project_id, registry_present)
      ON projects.id = project_registry.project_id
    SQL

    joined_relation.where(project_registry: { registry_present: [nil, false] })
  end

  def uploads
    if restricted_project_ids
      uploads_table   = Upload.arel_table
      group_uploads   = uploads_table[:model_type].eq('Namespace').and(uploads_table[:model_id].in(Gitlab::Geo.current_node.namespace_ids))
      project_uploads = uploads_table[:model_type].eq('Project').and(uploads_table[:model_id].in(restricted_project_ids))
      other_uploads   = uploads_table[:model_type].not_in(%w[Namespace Project])

      Upload.where(group_uploads.or(project_uploads).or(other_uploads))
    else
      Upload.all
    end
  end

  private

  def geo_api_url(suffix)
    URI.join(uri, "#{uri.path}/", "api/#{API::API.version}/geo/#{suffix}").to_s
  end

  def ensure_access_keys!
    return if self.access_key.present? && self.encrypted_secret_access_key.present?

    keys = Gitlab::Geo.generate_access_keys

    self.access_key = keys[:access_key]
    self.secret_access_key = keys[:secret_access_key]
  end

  def url_helper_args
    if relative_url_root
      relative_url = relative_url_root.starts_with?('/') ? relative_url_root : "/#{relative_url_root}"
    end

    { protocol: schema, host: host, port: port, script_name: relative_url }
  end

  def build_dependents
    build_geo_node_key if new_record? && secondary? && geo_node_key.nil?
  end

  def update_dependents_attributes
    if primary?
      self.geo_node_key = nil
    elsif uses_ssh_key?
      self.geo_node_key&.title = "Geo node: #{self.url}"
    end

    self.geo_node_key = nil unless uses_ssh_key? || geo_node_key&.persisted?

    if self.primary?
      self.oauth_application = nil
      update_clone_url
    else
      update_oauth_application!
    end
  end

  # Prevent locking yourself out
  def check_not_adding_primary_as_secondary
    if host == Gitlab.config.gitlab.host &&
        port == Gitlab.config.gitlab.port &&
        relative_url_root == Gitlab.config.gitlab.relative_url_root
      errors.add(:base, 'Current node must be the primary node or you will be locking yourself out')
    end
  end

  def update_clone_url
    self.clone_url_prefix = Gitlab.config.gitlab_shell.ssh_path_prefix
  end

  def update_oauth_application!
    self.build_oauth_application if oauth_application.nil?
    self.oauth_application.name = "Geo node: #{self.url}"
    self.oauth_application.redirect_uri = oauth_callback_url
  end

  def expire_cache!
    Gitlab::Geo.expire_cache!
  end
end
