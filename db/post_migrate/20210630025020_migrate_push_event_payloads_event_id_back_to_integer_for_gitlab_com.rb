# frozen_string_literal: true

require Rails.root.join('db', 'post_migrate', '20210622041846_finalize_push_event_payloads_bigint_conversion')

class MigratePushEventPayloadsEventIdBackToIntegerForGitlabCom < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    FinalizePushEventPayloadsBigintConversion.new.down
  end

  def down
    FinalizePushEventPayloadsBigintConversion.new.up
  end
end
