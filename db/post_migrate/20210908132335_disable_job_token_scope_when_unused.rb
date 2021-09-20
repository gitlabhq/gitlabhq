# frozen_string_literal: true

class DisableJobTokenScopeWhenUnused < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  class ProjectCiCdSetting < ApplicationRecord
    include EachBatch

    self.table_name = 'project_ci_cd_settings'
  end

  module Ci
    module JobToken
      class ProjectScopeLink < ApplicationRecord
        self.table_name = 'ci_job_token_project_scope_links'
      end
    end
  end

  def up
    # Disabling job token scope after db/migrate/20210902171808_set_default_job_token_scope_false.rb
    # if users haven't configured it.
    ProjectCiCdSetting.each_batch(of: 10_000) do |settings|
      with_enabled_but_unused_scope(settings).each_batch(of: 500) do |settings_to_update|
        settings_to_update.update_all(job_token_scope_enabled: false)
      end
    end
  end

  def down
    # irreversible data migration

    # The migration relies on the state of `job_token_scope_enabled` and
    # updates it based on whether the feature is used or not.
    #
    # The inverse migration would be to set `job_token_scope_enabled: true`
    # for those projects that have the feature disabled and unused. But there
    # could be also existing cases where the feature is disabled and unused.
    # For example, old projects.
  end

  private

  # The presence of ProjectScopeLinks means that the job token scope
  # is configured and we need to leave it enabled. Unused job token scope
  # can be disabled since they weren't configured.
  def with_enabled_but_unused_scope(settings)
    settings
      .where(job_token_scope_enabled: true)
      .where.not(project_id: Ci::JobToken::ProjectScopeLink.select(:source_project_id))
  end
end
