class Badge < ActiveRecord::Base
  # This structure sets the placeholders that the urls
  # can have. This hash also sets which action to ask when
  # the placeholder is found.
  PLACEHOLDERS = {
    'project_path' => :full_path,
    'project_id' => :id,
    'default_branch' => :default_branch,
    'commit_sha' => ->(project) { project.commit&.sha }
  }.freeze

  # This regex is built dynamically using the keys from the PLACEHOLDER struct.
  # So, we can easily add new placeholder just by modifying the PLACEHOLDER hash.
  # This regex will build the new PLACEHOLDER_REGEX with the new information
  PLACEHOLDERS_REGEX = /(#{PLACEHOLDERS.keys.join('|')})/.freeze

  default_scope { order_created_at_asc }

  scope :order_created_at_asc, -> { reorder(created_at: :asc) }

  validates :link_url, :image_url, url_placeholder: { protocols: %w(http https), placeholder_regex: PLACEHOLDERS_REGEX }
  validates :type, presence: true

  def rendered_link_url(project = nil)
    build_rendered_url(link_url, project)
  end

  def rendered_image_url(project = nil)
    build_rendered_url(image_url, project)
  end

  private

  def build_rendered_url(url, project = nil)
    return url unless valid? && project

    Gitlab::StringPlaceholderReplacer.replace_string_placeholders(url, PLACEHOLDERS_REGEX) do |arg|
      replace_placeholder_action(PLACEHOLDERS[arg], project)
    end
  end

  # The action param represents the :symbol or Proc to call in order
  # to retrieve the return value from the project.
  # This method checks if it is a Proc and use the call method, and if it is
  # a symbol just send the action
  def replace_placeholder_action(action, project)
    return unless project

    action.is_a?(Proc) ? action.call(project) : project.public_send(action) # rubocop:disable GitlabSecurity/PublicSend
  end
end
