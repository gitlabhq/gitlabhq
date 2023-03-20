# frozen_string_literal: true

module Namespaces
  class LdapSetting < ApplicationRecord
    belongs_to :namespace, inverse_of: :namespace_ldap_settings
    validates :namespace, presence: true

    self.primary_key = :namespace_id
    self.table_name = 'namespace_ldap_settings'
  end
end
