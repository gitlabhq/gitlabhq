# == Schema Information
#
# Table name: users_star_projects
#
#  id                 :integer          not null, primary key
#  starrer_id         :integer          not null
#  project_id         :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#

class UsersStarProject < ActiveRecord::Base
  belongs_to :project, counter_cache: :star_count
  belongs_to :user

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id] }
  validates :project, presence: true
end
