class ProjectFeature < ActiveRecord::Base
  # == Project features permissions
  #
  # Grants access level to project tools
  #
  # Tools can be enabled only for users, everyone or disabled
  # Access control is made only for non private projects
  #
  # levels:
  #
  # Disabled: not enabled for anyone
  # Private:  enabled only for team members
  # Enabled:  enabled for everyone able to access the project
  #

  # Permission levels
  DISABLED = 0
  PRIVATE  = 10
  ENABLED  = 20

  FEATURES = %i(issues merge_requests wiki snippets builds repository).freeze

  class << self
    def access_level_attribute(feature)
      feature = feature.model_name.plural.to_sym if feature.respond_to?(:model_name)
      raise ArgumentError, "invalid project feature: #{feature}" unless FEATURES.include?(feature)

      "#{feature}_access_level".to_sym
    end

    def quoted_access_level_column(feature)
      attribute = connection.quote_column_name(access_level_attribute(feature))
      table = connection.quote_table_name(table_name)

      "#{table}.#{attribute}"
    end
  end

  # Default scopes force us to unscope here since a service may need to check
  # permissions for a project in pending_delete
  # http://stackoverflow.com/questions/1540645/how-to-disable-default-scope-for-a-belongs-to
  belongs_to :project, -> { unscope(where: :pending_delete) }

  validates :project, presence: true

  validate :repository_children_level

  default_value_for :builds_access_level,         value: ENABLED, allows_nil: false
  default_value_for :issues_access_level,         value: ENABLED, allows_nil: false
  default_value_for :merge_requests_access_level, value: ENABLED, allows_nil: false
  default_value_for :snippets_access_level,       value: ENABLED, allows_nil: false
  default_value_for :wiki_access_level,           value: ENABLED, allows_nil: false
  default_value_for :repository_access_level,     value: ENABLED, allows_nil: false

  def feature_available?(feature, user)
    get_permission(user, access_level(feature))
  end

  def access_level(feature)
    public_send(ProjectFeature.access_level_attribute(feature)) # rubocop:disable GitlabSecurity/PublicSend
  end

  def builds_enabled?
    builds_access_level > DISABLED
  end

  def wiki_enabled?
    wiki_access_level > DISABLED
  end

  def merge_requests_enabled?
    merge_requests_access_level > DISABLED
  end

  def issues_enabled?
    issues_access_level > DISABLED
  end

  private

  # Validates builds and merge requests access level
  # which cannot be higher than repository access level
  def repository_children_level
    validator = lambda do |field|
      level = public_send(field) || ProjectFeature::ENABLED # rubocop:disable GitlabSecurity/PublicSend
      not_allowed = level > repository_access_level
      self.errors.add(field, "cannot have higher visibility level than repository access level") if not_allowed
    end

    %i(merge_requests_access_level builds_access_level).each(&validator)
  end

  def get_permission(user, level)
    case level
    when DISABLED
      false
    when PRIVATE
      user && (project.team.member?(user) || user.full_private_access?)
    when ENABLED
      true
    else
      true
    end
  end
end
