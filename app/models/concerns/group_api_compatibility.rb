# frozen_string_literal: true

# Add methods used by the groups API
module GroupAPICompatibility
  extend ActiveSupport::Concern

  def project_creation_level_str
    ::Gitlab::Access.project_creation_string_options.key(project_creation_level)
  end

  def project_creation_level_str=(value)
    write_attribute(:project_creation_level, ::Gitlab::Access.project_creation_string_options.fetch(value))
  end

  def subgroup_creation_level_str
    ::Gitlab::Access.subgroup_creation_string_options.key(subgroup_creation_level)
  end

  def subgroup_creation_level_str=(value)
    write_attribute(:subgroup_creation_level, ::Gitlab::Access.subgroup_creation_string_options.fetch(value))
  end
end
