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

  # Permision levels
  DISABLED = 0
  PRIVATE  = 10
  ENABLED  = 20

  FEATURES = %i(issues merge_requests wiki snippets builds)

  belongs_to :project

  def feature_available?(feature, user)
    raise ArgumentError, 'invalid project feature' unless FEATURES.include?(feature)

    get_permission(user, public_send("#{feature}_access_level"))
  end

  def builds_enabled?
    return true unless builds_access_level

    builds_access_level > DISABLED
  end

  def wiki_enabled?
    return true unless wiki_access_level

    wiki_access_level > DISABLED
  end

  def merge_requests_enabled?
    return true unless merge_requests_access_level

    merge_requests_access_level > DISABLED
  end

  private

  def get_permission(user, level)
    case level
    when DISABLED
      false
    when PRIVATE
      user && (project.team.member?(user) || user.admin?)
    when ENABLED
      true
    else
      true
    end
  end
end
