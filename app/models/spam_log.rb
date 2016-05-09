# == Schema Information
#
# Table name: spam_logs
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  source_ip     :string
#  user_agent    :string
#  via_api       :boolean
#  project_id    :integer
#  noteable_type :string
#  title         :string
#  description   :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class SpamLog < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  def remove_user
    user.block
    user.destroy
  end
end
