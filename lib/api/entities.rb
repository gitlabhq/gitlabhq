module Gitlab
  module Entities
    class User < Grape::Entity
      expose :id, :username, :email, :name, :bio, :skype, :linkedin, :twitter,
             :dark_scheme, :theme_id, :blocked, :created_at
    end

    class UserBasic < Grape::Entity
      expose :id, :username, :email, :name, :blocked, :created_at
    end

    class UserLogin < UserBasic
      expose :private_token
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at
    end

    class Project < Grape::Entity
      expose :id, :name, :description, :default_branch
      expose :owner, using: Entities::UserBasic
      expose :private_flag, as: :private
      expose :issues_enabled, :merge_requests_enabled, :wall_enabled, :wiki_enabled, :created_at
    end

    class ProjectMember < UserBasic
      expose :project_access, :as => :access_level do |user, options|
        options[:project].users_projects.find_by_user_id(user.id).project_access
      end
    end

    class RepoObject < Grape::Entity
      expose :name, :commit
    end

    class RepoCommit < Grape::Entity
      expose :id, :short_id, :title, :author_name, :author_email, :created_at
    end

    class ProjectSnippet < Grape::Entity
      expose :id, :title, :file_name
      expose :author, using: Entities::UserBasic
      expose :expires_at, :updated_at, :created_at
    end

    class Milestone < Grape::Entity
      expose :id
      expose (:project_id) {|milestone| milestone.project.id}
      expose :title, :description, :due_date, :closed, :updated_at, :created_at
    end

    class Issue < Grape::Entity
      expose :id
      expose (:project_id) {|issue| issue.project.id}
      expose :title, :description
      expose :label_list, as: :labels
      expose :milestone, using: Entities::Milestone
      expose :assignee, :author, using: Entities::UserBasic
      expose :closed, :updated_at, :created_at
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end

    class MergeRequest < Grape::Entity
      expose :id, :target_branch, :source_branch, :project_id, :title, :closed, :merged
      expose :author, :assignee, using: Entities::UserBasic
    end

    class Note < Grape::Entity
      expose :id
      expose :note, as: :body
      expose :author, using: Entities::UserBasic
      expose :created_at
    end

    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end
  end
end
