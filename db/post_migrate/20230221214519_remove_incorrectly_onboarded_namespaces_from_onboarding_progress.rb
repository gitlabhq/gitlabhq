# frozen_string_literal: true

class RemoveIncorrectlyOnboardedNamespacesFromOnboardingProgress < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class OnboardingProgress < MigrationRecord
    include EachBatch

    self.table_name = 'onboarding_progresses'
  end

  class Project < MigrationRecord
    self.table_name = 'projects'
  end

  def up
    names = ['Learn GitLab', 'Learn GitLab - Ultimate trial']

    OnboardingProgress.each_batch(of: 500) do |batch|
      namespaces_to_keep = Project.where(name: names, namespace_id: batch.select(:namespace_id)).select(:namespace_id)
      batch.where.not(namespace_id: namespaces_to_keep).delete_all
    end
  end

  def down
    # no op
  end
end
