# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class ProjectImportData < ApplicationRecord
  prepend_mod_with('ProjectImportData') # rubocop: disable Cop/InjectEnterpriseEditionModule

  belongs_to :project, inverse_of: :import_data
  attr_encrypted :credentials,
                 key: Settings.attr_encrypted_db_key_base,
                 marshal: true,
                 encode: true,
                 mode: :per_attribute_iv_and_salt,
                 insecure_mode: true,
                 algorithm: 'aes-256-cbc'

  serialize :data, JSON # rubocop:disable Cop/ActiveRecordSerialize

  validates :project, presence: true

  before_validation :symbolize_credentials

  def symbolize_credentials
    # bang doesn't work here - attr_encrypted makes it not to work
    self.credentials = self.credentials.deep_symbolize_keys unless self.credentials.blank?
  end

  def merge_data(hash)
    self.data = data.to_h.merge(hash) unless hash.empty?
  end

  def merge_credentials(hash)
    self.credentials = credentials.to_h.merge(hash) unless hash.empty?
  end

  def clear_credentials
    self.credentials = {}
  end
end
