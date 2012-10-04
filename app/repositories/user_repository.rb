module UserRepository
  included do
    scope :not_in_project, ->(project) { where("id not in (:ids)", ids: project.users.map(&:id) ) }
    scope :admins, where(admin:  true)
    scope :blocked, where(blocked:  true)
    scope :active, where(blocked:  false)
  end
end
