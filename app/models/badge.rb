# frozen_string_literal: true

class Badge < ApplicationRecord
  include FromUnion

  # This structure sets the placeholders that the urls
  # can have. This hash also sets which action to ask when
  # the placeholder is found.
  PLACEHOLDERS = {
    'project_path' => :full_path,
    'project_title' => :title,
    'project_name' => :path,
    'project_id' => :id,
    'project_namespace' => ->(project) { project.project_namespace.to_param },
    'group_name' => ->(project) { project.group&.to_param },
    'gitlab_server' => proc { Gitlab.config.gitlab.host },
    'gitlab_pages_domain' => proc { Gitlab.config.pages.host },
    'default_branch' => :default_branch,
    'commit_sha' => ->(project) { project.commit&.sha },
    'latest_tag' => ->(project) do
      TagsFinder.new(project.repository, per_page: 1, sort: 'updated_desc').execute.first&.name if project.repository
    end
  }.freeze

  # This regex is built dynamically using the keys from the PLACEHOLDER struct.
  # So, we can easily add new placeholder just by modifying the PLACEHOLDER hash.
  # This regex will build the new PLACEHOLDER_REGEX with the new information
  PLACEHOLDERS_REGEX = /(#{PLACEHOLDERS.keys.join('|')})/

  default_scope { order_created_at_asc } # rubocop:disable Cop/DefaultScope

  scope :order_created_at_asc, -> { reorder(created_at: :asc) }

  scope :with_name, ->(name) { where(name: name) }

  validates :link_url, :image_url, addressable_url: true
  validates :type, presence: true

  def rendered_link_url(project = nil)
    build_rendered_url(link_url, project)
  end

  def rendered_image_url(project = nil)
    Gitlab::AssetProxy.proxy_url(
      build_rendered_url(image_url, project)
    )
  end

  private

  def build_rendered_url(url, project = nil)
    return url unless project

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
