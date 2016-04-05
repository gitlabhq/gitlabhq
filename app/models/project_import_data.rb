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
  attr_encrypted :credentials, key: Gitlab::Application.secrets.db_key_base, marshal: true, encode: true, mode: :per_attribute_iv_and_salt

  serialize :data, JSON

  validates :project, presence: true

  # TODO: This doesnt play well with attr_encrypted. Perhaps consider extending Marshall and specify a different Marshaller
  before_validation :symbolize_credentials

  def symbolize_credentials
    return if credentials.blank?
    credentials.deep_symbolize_keys!
  end
end
