# frozen_string_literal: true

module Authz
  class PersonalAccessTokenGranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :personal_access_token, optional: false
    belongs_to :granular_scope, optional: false
  end
end
