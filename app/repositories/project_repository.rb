module ProjectRepository
  incuded do
    scope :public_only, where(private_flag: false)
    scope :without_user, ->(user)  { where("id NOT IN (:ids)", ids: user.projects.map(&:id) ) }
    scope :not_in_group, ->(group) { where("id NOT IN (:ids)", ids: group.project_ids ) }
  end
end
