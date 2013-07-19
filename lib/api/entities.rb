module API
  module Entities
    class User < Grape::Entity
      expose :id, :username, :email, :name, :bio, :skype, :linkedin, :twitter,
             :theme_id, :color_scheme_id, :state, :created_at, :extern_uid, :provider
    end

    class UserSafe < Grape::Entity
      expose :name
    end

    class UserBasic < Grape::Entity
      expose :id, :username, :email, :name, :state, :created_at
    end

    class UserLogin < User
      expose :private_token
      expose :is_admin?, as: :is_admin
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
      expose :can_create_team?, as: :can_create_team
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at
    end

    class ForkedFromProject < Grape::Entity
      expose :id
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
    end

    class Project < Grape::Entity
      expose :id, :description, :default_branch, :public, :ssh_url_to_repo, :http_url_to_repo, :web_url
      expose :owner, using: Entities::UserBasic
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :issues_enabled, :merge_requests_enabled, :wall_enabled, :wiki_enabled, :snippets_enabled, :created_at, :last_activity_at, :public
      expose :namespace
      expose :forked_from_project, using: Entities::ForkedFromProject, :if => lambda{ | project, options | project.forked? }
    end

    class ProjectMember < UserBasic
      expose :project_access, as: :access_level do |user, options|
        options[:project].users_projects.find_by_user_id(user.id).project_access
      end
    end

    class TeamMember < UserBasic
      expose :permission, as: :access_level do |user, options|
        options[:user_team].user_team_user_relationships.find_by_user_id(user.id).permission
      end
    end

    class TeamProject < Project
      expose :greatest_access, as: :greatest_access_level do |project, options|
        options[:user_team].user_team_project_relationships.find_by_project_id(project.id).greatest_access
      end
    end

    class Group < Grape::Entity
      expose :id, :name, :path, :owner_id
    end

    class GroupDetail < Group
      expose :projects, using: Entities::Project
    end

    class RepoObject < Grape::Entity
      expose :name, :commit
      expose :protected do |repo, options|
        if options[:project]
          options[:project].protected_branch? repo.name
        end
      end
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
      expose :title, :description, :due_date, :state, :updated_at, :created_at
    end

    class Issue < Grape::Entity
      expose :id
      expose (:project_id) {|issue| issue.project.id}
      expose :title, :description
      expose :label_list, as: :labels
      expose :milestone, using: Entities::Milestone
      expose :assignee, :author, using: Entities::UserBasic
      expose :state, :updated_at, :created_at
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end

    class MergeRequest < Grape::Entity
      expose :id, :target_branch, :source_branch, :project_id, :title, :state
      expose :author, :assignee, using: Entities::UserBasic
    end

    class Note < Grape::Entity
      expose :id
      expose :note, as: :body
      expose :attachment_identifier, as: :attachment
      expose :author, using: Entities::UserBasic
      expose :created_at
    end

    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end

    class Event < Grape::Entity
      expose :title, :project_id, :action_name
      expose :target_id, :target_type, :author_id
      expose :data, :target_title
    end
  end
end
