# frozen_string_literal: true

module Authn
  class PersonalAccessTokenLastUsedIp < ApplicationRecord
    self.table_name = 'personal_access_token_last_used_ips'
    belongs_to :personal_access_token
    belongs_to :organization, class_name: 'Organizations::Organization'
  end
end
