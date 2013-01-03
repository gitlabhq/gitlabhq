# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#

class Service < ActiveRecord::Base
  attr_accessible :title, :token, :type, :active

  belongs_to :project
  has_one :service_hook

  validates :project_id, presence: true

  def activated?
    active
  end
end
