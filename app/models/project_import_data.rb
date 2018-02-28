require 'carrierwave/orm/activerecord'

class ProjectImportData < ActiveRecord::Base
  belongs_to :project, inverse_of: :import_data
  attr_encrypted :credentials,
                 key: Gitlab::Application.secrets.db_key_base,
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
end
