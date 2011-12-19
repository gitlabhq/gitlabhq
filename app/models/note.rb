require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Note < ActiveRecord::Base
  belongs_to :project
  belongs_to :noteable, :polymorphic => true
  belongs_to :author,
    :class_name => "User"

  delegate :name,
           :email,
           :to => :author,
           :prefix => true

  attr_protected :author, :author_id
  attr_accessor :notify

  validates_presence_of :project

  validates :note,
            :presence => true,
            :length   => { :within => 0..5000 }

  validates :attachment,
            :file_size => {
              :maximum => 10.megabytes.to_i
            }

  scope :common, where(:noteable_id => nil)

  scope :today, where("created_at >= :date", :date => Date.today)
  scope :last_week, where("created_at  >= :date", :date => (Date.today - 7.days))
  scope :since, lambda { |day| where("created_at  >= :date", :date => (day)) }
  scope :fresh, order("created_at DESC")
  scope :inc_author_project, includes(:project, :author)
  scope :inc_author, includes(:author)

  mount_uploader :attachment, AttachmentUploader

  def notify
    @notify ||= false
  end
end
# == Schema Information
#
# Table name: notes
#
#  id            :integer         not null, primary key
#  note          :text
#  noteable_id   :string(255)
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#

