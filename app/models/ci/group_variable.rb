# frozen_string_literal: true

module Ci
  class GroupVariable < Ci::ApplicationRecord
    include Ci::HasVariable
    include Ci::Maskable
    include Ci::RawVariable
    include Limitable
    include Presentable

    prepend HasEnvironmentScope

    belongs_to :group, class_name: "::Group"

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      scope: [:group_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
    scope :by_environment_scope, -> (environment_scope) { where(environment_scope: environment_scope) }
    scope :for_groups, ->(group_ids) { where(group_id: group_ids) }

    scope :for_environment_scope_like, -> (query) do
      top_level = 'LOWER(ci_group_variables.environment_scope) LIKE LOWER(?) || \'%\''
      search_like = "%#{sanitize_sql_like(query)}%"

      where(top_level, search_like)
    end

    scope :environment_scope_names, -> do
      group(:environment_scope)
      .order(:environment_scope)
      .pluck(:environment_scope)
    end

    self.limit_name = 'group_ci_variables'
    self.limit_scope = :group

    def audit_details
      key
    end

    def group_name
      group.name
    end

    def group_ci_cd_settings_path
      Gitlab::Routing.url_helpers.group_settings_ci_cd_path(group)
    end
  end
end
