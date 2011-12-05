UsersProject.seed(:id, [
  { :id => 1,  :project_id => 1, :user_id => 1, :read => true, :write => true,  :admin => true  },
  { :id => 2,  :project_id => 1, :user_id => 2, :read => true, :write => false, :admin => false },
  { :id => 3,  :project_id => 1, :user_id => 3, :read => true, :write => false, :admin => false },
  { :id => 4,  :project_id => 1, :user_id => 4, :read => true, :write => false, :admin => false },
  { :id => 5,  :project_id => 1, :user_id => 5, :read => true, :write => false, :admin => false },

  { :id => 6,  :project_id => 2, :user_id => 1, :read => true, :write => true,  :admin => true  },
  { :id => 7,  :project_id => 2, :user_id => 2, :read => true, :write => false, :admin => false },
  { :id => 8,  :project_id => 2, :user_id => 3, :read => true, :write => false, :admin => false },
  { :id => 9,  :project_id => 2, :user_id => 4, :read => true, :write => false, :admin => false },
  { :id => 11, :project_id => 2, :user_id => 5, :read => true, :write => false, :admin => false },

  { :id => 12, :project_id => 3, :user_id => 1, :read => true, :write => true,  :admin => true  },
  { :id => 13, :project_id => 3, :user_id => 2, :read => true, :write => false, :admin => false },
  { :id => 14, :project_id => 3, :user_id => 3, :read => true, :write => false, :admin => false },
  { :id => 15, :project_id => 3, :user_id => 4, :read => true, :write => false, :admin => false },
  { :id => 16, :project_id => 3, :user_id => 5, :read => true, :write => false, :admin => false }
])


