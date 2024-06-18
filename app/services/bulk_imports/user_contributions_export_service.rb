# frozen_string_literal: true

module BulkImports
  class UserContributionsExportService
    def initialize(user_id, portable, jid)
      @user = User.find(user_id)
      @portable = portable
      @jid = jid
    end

    def execute
      # Set up query to get cached users and set it as user_contributions on the portable model
      @portable.user_contributions = UserContributionsExportMapper.new(@portable).get_contributing_users
      relation = BulkImports::FileTransfer::BaseConfig::USER_CONTRIBUTIONS_RELATION

      RelationExportService.new(@user, @portable, relation, @jid).execute
    end
  end
end
