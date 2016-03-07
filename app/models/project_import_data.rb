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
  attr_encrypted :credentials, key: Gitlab::Application.secrets.db_key_base, marshal: true, encode: true

  serialize :data, JSON

  validates :project, presence: true
end
