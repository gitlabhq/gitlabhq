# frozen_string_literal: true

# Add methods used by the projects API
module ProjectAPICompatibility
  extend ActiveSupport::Concern

  def build_git_strategy=(value)
    write_attribute(:build_allow_git_fetch, value == 'fetch')
  end

  def auto_devops_enabled=(value)
    (auto_devops || build_auto_devops).enabled = value
  end

  def auto_devops_deploy_strategy=(value)
    (auto_devops || build_auto_devops).deploy_strategy = value
  end
end
