# frozen_string_literal: true

module BulkImports
  class UserContributionsExportService
    def initialize(user_id, portable, jid, offline_export_id)
      @user = User.find(user_id)
      @portable = portable
      @jid = jid
      @offline_export_id = offline_export_id
    end

    def execute
      # Set up query to get cached users and set it as user_contributions on the portable model
      @portable.user_contributions = UserContributionsExportMapper.new(@portable).get_contributing_users
      relation = BulkImports::FileTransfer::BaseConfig::USER_CONTRIBUTIONS_RELATION

      RelationExportService.new(@user, @portable, relation, @jid, offline_export_id: @offline_export_id).execute
    end
  end
end
