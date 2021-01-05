# frozen_string_literal: true

class Namespace::PackageSetting < ApplicationRecord
  self.primary_key = :namespace_id
  self.table_name = 'namespace_package_settings'

  belongs_to :namespace, inverse_of: :package_setting_relation

  validates :namespace, presence: true
  validates :maven_duplicates_allowed, inclusion: { in: [true, false] }
  validates :maven_duplicate_exception_regex, untrusted_regexp: true, length: { maximum: 255 }
end
