# frozen_string_literal: true

class MigrateOpsFeatureFlagsScopesTargetUserIds < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class OperationsFeatureFlagScope < ActiveRecord::Base
    include EachBatch
    self.table_name = 'operations_feature_flag_scopes'
    self.inheritance_column = :_type_disabled
  end

  ###
  # 2019-11-26
  #
  # There are about 1000 rows in the operations_feature_flag_scopes table on gitlab.com.
  # This migration will update about 30 of them.
  # https://gitlab.com/gitlab-org/gitlab/merge_requests/20325#note_250742098
  #
  # This should take a few seconds to run.
  # https://gitlab.com/gitlab-org/gitlab/merge_requests/20325#note_254871603
  #
  ###
  def up
    OperationsFeatureFlagScope.where("strategies @> ?", [{ 'name': 'userWithId' }].to_json).each_batch do |scopes|
      scopes.each do |scope|
        if scope.active
          default_strategy = scope.strategies.find { |s| s['name'] == 'default' }

          if default_strategy.present?
            scope.update({ strategies: [default_strategy] })
          end
        else
          user_with_id_strategy = scope.strategies.find { |s| s['name'] == 'userWithId' }

          scope.update({
            active: true,
            strategies: [user_with_id_strategy]
          })
        end
      end
    end
  end

  def down
    # This is not reversible.
    # The old Target Users feature required the same list of user ids to be applied to each environment scope.
    # Now we allow the list of user ids to differ for each scope.
  end
end
