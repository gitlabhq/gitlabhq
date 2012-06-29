module Gitlab
  module Entities
    class User < Grape::Entity
      expose :id, :email, :name, :bio, :skype, :linkedin, :twitter,
             :dark_scheme, :theme_id, :blocked, :created_at
    end

    class Project < Grape::Entity
      expose :id, :code, :name, :description, :path, :default_branch
      expose :owner, :using => Entities::User
      expose :private_flag, :as => :private
      expose :issues_enabled, :merge_requests_enabled, :wall_enabled, :wiki_enabled, :created_at
    end

    class ProjectRepositoryBranches < Grape::Entity
      expose :name, :commit
    end

    class ProjectRepositoryTags < Grape::Entity
      expose :name, :commit
    end
  end
end
