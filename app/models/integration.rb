class Integration < ActiveRecord::Base
  belongs_to :project, required: true, validate: true

  validates :name, presence: true
  validates :external_token, presence: true, uniqueness: true
end
