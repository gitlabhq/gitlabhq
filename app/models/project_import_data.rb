# == Schema Information
#
# Table name: project_import_data
#
#  id         :integer          not null, primary key
#  project_id :integer
#  data       :text
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class ProjectImportData < ActiveRecord::Base
  belongs_to :project
  attr_encrypted :credentials,
                 key: Gitlab::Application.secrets.db_key_base,
                 marshal: true,
                 encode: true,
                 mode: :per_attribute_iv_and_salt

  serialize :data, JSON

  validates :project, presence: true

  before_validation :symbolize_credentials

  def symbolize_credentials
    # bang doesn't work here - attr_encrypted makes it not to work
    self.credentials = self.credentials.deep_symbolize_keys unless self.credentials.blank?
  end
end
