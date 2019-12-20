# frozen_string_literal: true

class ProjectCiCdSetting < ApplicationRecord
  include IgnorableColumns
  # https://gitlab.com/gitlab-org/gitlab/issues/36651
  ignore_column :merge_trains_enabled, remove_with: '12.7', remove_after: '2019-12-22'

  belongs_to :project, inverse_of: :ci_cd_settings

  # The version of the schema that first introduced this model/table.
  MINIMUM_SCHEMA_VERSION = 20180403035759

  DEFAULT_GIT_DEPTH = 50

  before_create :set_default_git_depth

  validates :default_git_depth,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    },
    allow_nil: true

  def self.available?
    @available ||=
      ActiveRecord::Migrator.current_version >= MINIMUM_SCHEMA_VERSION
  end

  def self.reset_column_information
    @available = nil
    super
  end

  private

  def set_default_git_depth
    return unless Feature.enabled?(:ci_set_project_default_git_depth, default_enabled: true)

    self.default_git_depth ||= DEFAULT_GIT_DEPTH
  end
end

ProjectCiCdSetting.prepend_if_ee('EE::ProjectCiCdSetting')
