class UserCallout < ActiveRecord::Base
  belongs_to :user

  enum feature_name: {
    gke_cluster_integration: 0
  }

  validates :user, presence: true
  validates :feature_name,
    presence: true,
    uniqueness: { scope: :user_id },
    inclusion: { in: UserCallout.feature_names.keys }
end
