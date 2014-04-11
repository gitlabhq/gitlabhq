# == Schema Information
#
# Table name: project_templates
#
#  id          :integer          not null, primary key
#  name        :string(100)
#  save_name   :string(200)      not null
#  description :text
#  upload      :string(400)
#  state       :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

# state information
# state = 0 => uploaded, but has to be unzipped (default)
# state = 1 => successfully created
# state = 2 => error occured while/after unzipping
# state = 3 => template will be destroyed

require 'carrierwave/orm/activerecord'

class ProjectTemplate < ActiveRecord::Base

  include ActionView::Helpers::NumberHelper

  # Properties
  default_value_for :template_name_length, 100
  default_value_for :template_description_length, 750

  attr_accessor :template_name_length, :template_description_length

  attr_accessible :name, :description, :upload

  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name

  validates :name, length: {maximum: 100 }
  validates :description, length: { maximum: 750 }, allow_blank: true

  mount_uploader :upload, ProjectTemplateUploader
  validates_presence_of :upload, {:message => '- Please choose a file to upload!'}
  validate :upload_type
  validate :file_size

  def max_upload_size
    number_to_human_size(Gitlab.config.gitlab.templates_max_filesize, precision: 2, separator: '.')
  end

  def saved?
    id && persisted?
  end

  def template_path
    File.join(Gitlab.config.gitlab.templates_path, "#{id}", "#{save_name}")
  end

  def template_delete_path
    File.join(Gitlab.config.gitlab.templates_path, "#{id}")
  end

  def upload_type
    unless self.upload.zip?
      self.errors.add :upload, "- Only *.zip files are allowed"
    end
  end

  def file_size
    if self.upload.file != nil
      unless self.upload.file.size < Gitlab.config.gitlab.templates_max_filesize
        self.errors.add :upload, "- Your file is too big: max. #{self.max_upload_size}"
      end
    else
      self.errors.add :upload, " - Please choose a file to upload!"
    end
  end

  def deletable?
    state != 0 && state != 3
  end

  def usable?
    state == 1
  end

end
