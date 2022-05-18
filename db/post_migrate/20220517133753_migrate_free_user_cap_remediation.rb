# frozen_string_literal: true

class MigrateFreeUserCapRemediation < Gitlab::Database::Migration[2.0]
  def up
    sidekiq_queue_migrate 'cronjob:namespaces_free_user_cap', to: 'cronjob:namespaces_free_user_cap_remediation'
  end

  def down
    sidekiq_queue_migrate 'cronjob:namespaces_free_user_cap_remediation', to: 'cronjob:namespaces_free_user_cap'
  end
end
