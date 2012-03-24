UsersProject.seed(:id, [
  { :id => 1,  :project_id => 1, :user_id => 1, :project_access => UsersProject::MASTER },
  { :id => 2,  :project_id => 1, :user_id => 2, :project_access => UsersProject::REPORTER},
  { :id => 3,  :project_id => 1, :user_id => 3, :project_access => UsersProject::REPORTER},
  { :id => 4,  :project_id => 1, :user_id => 4, :project_access => UsersProject::REPORTER},
  { :id => 5,  :project_id => 1, :user_id => 5, :project_access => UsersProject::REPORTER},

  { :id => 6,  :project_id => 2, :user_id => 1, :project_access => UsersProject::MASTER },
  { :id => 7,  :project_id => 2, :user_id => 2, :project_access => UsersProject::REPORTER},
  { :id => 8,  :project_id => 2, :user_id => 3, :project_access => UsersProject::REPORTER},
  { :id => 9,  :project_id => 2, :user_id => 4, :project_access => UsersProject::MASTER},
  { :id => 11, :project_id => 2, :user_id => 5, :project_access => UsersProject::MASTER},

  { :id => 12, :project_id => 3, :user_id => 1, :project_access => UsersProject::MASTER },
  { :id => 13, :project_id => 3, :user_id => 2, :project_access => UsersProject::REPORTER},
  { :id => 14, :project_id => 3, :user_id => 3, :project_access => UsersProject::MASTER},
  { :id => 15, :project_id => 3, :user_id => 4, :project_access => UsersProject::REPORTER},
  { :id => 16, :project_id => 3, :user_id => 5, :project_access => UsersProject::MASTER}
])


