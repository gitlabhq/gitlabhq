module Gitlab
  module Entities
    class User < Grape::Entity
      expose :id, :email, :name, :bio, :skype, :linkedin, :twitter,
             :dark_scheme, :theme_id, :blocked, :created_at
    end

    class UserBasic < Grape::Entity
      expose :id, :email, :name, :blocked, :created_at
    end

    class Project < Grape::Entity
      expose :id, :code, :name, :description, :path, :default_branch
      expose :owner, :using => Entities::UserBasic
      expose :private_flag, :as => :private
      expose :issues_enabled, :merge_requests_enabled, :wall_enabled, :wiki_enabled, :created_at
    end

    class ProjectRepositoryBranches < Grape::Entity
      expose :name, :commit
    end

    class ProjectRepositoryTags < Grape::Entity
      expose :name, :commit
    end

    class ProjectSnippet < Grape::Entity
      expose :id, :title, :file_name
      expose :author, :using => Entities::UserBasic
      expose :expires_at, :updated_at, :created_at
    end
  end
end
