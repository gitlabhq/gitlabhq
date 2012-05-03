module Project::ValidationsTrait
  as_trait do
    validates :name,
              :uniqueness => true,
              :presence => true,
              :length   => { :within => 0..255 }

    validates :path,
              :uniqueness => true,
              :presence => true,
              :format => { :with => /^[a-zA-Z0-9_\-\.]*$/,
                           :message => "only letters, digits & '_' '-' '.' allowed" },
              :length   => { :within => 0..255 }

    validates :description,
              :length   => { :within => 0..2000 }

    validates :code,
              :presence => true,
              :uniqueness => true,
              :format => { :with => /^[a-zA-Z0-9_\-\.]*$/,
                           :message => "only letters, digits & '_' '-' '.' allowed"  },
              :length   => { :within => 1..255 }

    validates :owner, :presence => true
    validate :check_limit
    validate :repo_name

    def check_limit
      unless owner.can_create_project?
        errors[:base] << ("Your own projects limit is #{owner.projects_limit}! Please contact administrator to increase it")
      end
    rescue
      errors[:base] << ("Cant check your ability to create project")
    end

    def repo_name
      if path == "gitolite-admin"
        errors.add(:path, " like 'gitolite-admin' is not allowed")
      end
    end
  end
end
