# frozen_string_literal: true

# This is a temporary table used to archive OAuth access token records during the cleanup phase.
# It stores historical data that needs to be preserved before permanent deletion from the main table.
# Cleanup issue: https://gitlab.com/gitlab-org/gitlab/-/issues/562373
module Authn
  class OauthAccessTokenArchivedRecord < ApplicationRecord
    self.table_name = 'oauth_access_token_archived_records'
  end
end
