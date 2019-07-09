# frozen_string_literal: true

# Add methods used by the projects API
module ProjectAPICompatibility
  extend ActiveSupport::Concern

  def build_git_strategy=(value)
    write_attribute(:build_allow_git_fetch, value == 'fetch')
  end

  def auto_devops_enabled=(value)
    self.build_auto_devops if self.auto_devops&.enabled.nil?
    self.auto_devops.update! enabled: value
  end

  def auto_devops_deploy_strategy=(value)
    self.build_auto_devops if self.auto_devops&.enabled.nil?
    self.auto_devops.update! deploy_strategy: value
  end
end
