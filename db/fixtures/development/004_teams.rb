UsersProject.seed(:id, [
  { :id => 1,  :project_id => 1, :user_id => 1, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_RW },
  { :id => 2,  :project_id => 1, :user_id => 2, :project_access => Project::PROJECT_RW,  :repo_access => Repository::REPO_N },
  { :id => 3,  :project_id => 1, :user_id => 3, :project_access => Project::PROJECT_RW,  :repo_access => Repository::REPO_N },
  { :id => 4,  :project_id => 1, :user_id => 4, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },
  { :id => 5,  :project_id => 1, :user_id => 5, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },

  { :id => 6,  :project_id => 2, :user_id => 1, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_RW },
  { :id => 7,  :project_id => 2, :user_id => 2, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },
  { :id => 8,  :project_id => 2, :user_id => 3, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },
  { :id => 9,  :project_id => 2, :user_id => 4, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_N },
  { :id => 11, :project_id => 2, :user_id => 5, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_N },

  { :id => 12, :project_id => 3, :user_id => 1, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_RW },
  { :id => 13, :project_id => 3, :user_id => 2, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },
  { :id => 14, :project_id => 3, :user_id => 3, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_N },
  { :id => 15, :project_id => 3, :user_id => 4, :project_access => Project::PROJECT_R,   :repo_access => Repository::REPO_N },
  { :id => 16, :project_id => 3, :user_id => 5, :project_access => Project::PROJECT_RWA, :repo_access => Repository::REPO_N }
])


