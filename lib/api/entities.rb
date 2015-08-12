module API
  module Entities
    class UserSafe < Grape::Entity
      expose :name, :username
    end

    class UserBasic < UserSafe
      expose :id, :state, :avatar_url

      expose :web_url do |user, options|
        Rails.application.routes.url_helpers.user_url(user)
      end
    end

    class User < UserBasic
      expose :created_at
      expose :is_admin?, as: :is_admin
      expose :bio, :skype, :linkedin, :twitter, :website_url
    end

    class Identity < Grape::Entity
      expose :provider, :extern_uid
    end

    class UserFull < User
      expose :email
      expose :theme_id, :color_scheme_id, :projects_limit, :current_sign_in_at
      expose :identities, using: Entities::Identity
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
      expose :two_factor_enabled
    end

    class UserLogin < UserFull
      expose :private_token
    end

    class Email < Grape::Entity
      expose :id, :email
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at
    end

    class ProjectHook < Hook
      expose :project_id, :push_events
      expose :issues_events, :merge_requests_events, :tag_push_events
    end

    class ForkedFromProject < Grape::Entity
      expose :id
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
    end

    class Project < Grape::Entity
      expose :id, :description, :default_branch, :tag_list
      expose :public?, as: :public
      expose :archived?, as: :archived
      expose :visibility_level, :ssh_url_to_repo, :http_url_to_repo, :web_url
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :issues_enabled, :merge_requests_enabled, :wiki_enabled, :snippets_enabled, :created_at, :last_activity_at
      expose :creator_id
      expose :namespace
      expose :forked_from_project, using: Entities::ForkedFromProject, if: lambda{ | project, options | project.forked? }
      expose :avatar_url
      expose :star_count, :forks_count
    end

    class ProjectMember < UserBasic
      expose :access_level do |user, options|
        options[:project].project_members.find_by(user_id: user.id).access_level
      end
    end

    class Group < Grape::Entity
      expose :id, :name, :path, :description
      expose :avatar_url

      expose :web_url do |group, options|
        Rails.application.routes.url_helpers.group_url(group)
      end
    end

    class GroupDetail < Group
      expose :projects, using: Entities::Project
    end

    class GroupMember < UserBasic
      expose :access_level do |user, options|
        options[:group].group_members.find_by(user_id: user.id).access_level
      end
    end

    class RepoTag < Grape::Entity
      expose :name
      expose :message do |repo_obj, _options|
        if repo_obj.respond_to?(:message)
          repo_obj.message
        else
          nil
        end
      end

      expose :commit do |repo_obj, options|
        if repo_obj.respond_to?(:commit)
          repo_obj.commit
        elsif options[:project]
          options[:project].repository.commit(repo_obj.target)
        end
      end
    end

    class RepoObject < Grape::Entity
      expose :name

      expose :commit do |repo_obj, options|
        if repo_obj.respond_to?(:commit)
          repo_obj.commit
        elsif options[:project]
          options[:project].repository.commit(repo_obj.target)
        end
      end

      expose :protected do |repo, options|
        if options[:project]
          options[:project].protected_branch? repo.name
        end
      end
    end

    class RepoTreeObject < Grape::Entity
      expose :id, :name, :type

      expose :mode do |obj, options|
        filemode = obj.mode.to_s(8)
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end

    class RepoCommit < Grape::Entity
      expose :id, :short_id, :title, :author_name, :author_email, :created_at
      expose :safe_message, as: :message
    end

    class RepoCommitDetail < RepoCommit
      expose :parent_ids, :committed_date, :authored_date
    end

    class ProjectSnippet < Grape::Entity
      expose :id, :title, :file_name
      expose :author, using: Entities::UserBasic
      expose :expires_at, :updated_at, :created_at
    end

    class ProjectEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity.project.id }
      expose :title, :description
      expose :state, :created_at, :updated_at
    end

    class RepoDiff < Grape::Entity
      expose :old_path, :new_path, :a_mode, :b_mode, :diff
      expose :new_file, :renamed_file, :deleted_file
    end

    class Milestone < ProjectEntity
      expose :due_date
    end

    class Issue < ProjectEntity
      expose :label_names, as: :labels
      expose :milestone, using: Entities::Milestone
      expose :assignee, :author, using: Entities::UserBasic
    end

    class MergeRequest < ProjectEntity
      expose :target_branch, :source_branch, :upvotes, :downvotes
      expose :author, :assignee, using: Entities::UserBasic
      expose :source_project_id, :target_project_id
      expose :label_names, as: :labels
      expose :description
      expose :work_in_progress?, as: :work_in_progress
      expose :milestone, using: Entities::Milestone
    end

    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::RepoDiff do |compare, _|
        compare.diffs
      end
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end

    class Note < Grape::Entity
      expose :id
      expose :note, as: :body
      expose :attachment_identifier, as: :attachment
      expose :author, using: Entities::UserBasic
      expose :created_at
      expose :system?, as: :system
      expose :upvote?, as: :upvote
      expose :downvote?, as: :downvote
    end

    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end

    class CommitNote < Grape::Entity
      expose :note
      expose(:path) { |note| note.diff_file_name }
      expose(:line) { |note| note.diff_new_line }
      expose(:line_type) { |note| note.diff_line_type }
      expose :author, using: Entities::UserBasic
    end

    class Event < Grape::Entity
      expose :title, :project_id, :action_name
      expose :target_id, :target_type, :author_id
      expose :data, :target_title
      expose :created_at

      expose :author_username do |event, options|
        if event.author
          event.author.username
        end
      end
    end

    class Namespace < Grape::Entity
      expose :id, :path, :kind
    end

    class ProjectAccess < Grape::Entity
      expose :access_level
      expose :notification_level
    end

    class GroupAccess < Grape::Entity
      expose :access_level
      expose :notification_level
    end

    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          project.project_members.find_by(user_id: options[:user].id)
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            project.group.group_members.find_by(user_id: options[:user].id)
          end
        end
      end
    end

    class Label < Grape::Entity
      expose :name, :color
    end

    class Compare < Grape::Entity
      expose :commit, using: Entities::RepoCommit do |compare, options|
        Commit.decorate(compare.commits, nil).last
      end

      expose :commits, using: Entities::RepoCommit do |compare, options|
        Commit.decorate(compare.commits, nil)
      end

      expose :diffs, using: Entities::RepoDiff do |compare, options|
        compare.diffs
      end

      expose :compare_timeout do |compare, options|
        compare.timeout
      end

      expose :same, as: :compare_same_ref
    end

    class Contributor < Grape::Entity
      expose :name, :email, :commits, :additions, :deletions
    end

    class BroadcastMessage < Grape::Entity
      expose :message, :starts_at, :ends_at, :color, :font
    end

    class ApplicationSetting < Grape::Entity
      expose :id
      expose :default_projects_limit
      expose :signup_enabled
      expose :signin_enabled
      expose :gravatar_enabled
      expose :sign_in_text
      expose :created_at
      expose :updated_at
      expose :home_page_url
      expose :default_branch_protection
      expose :twitter_sharing_enabled
      expose :restricted_visibility_levels
      expose :max_attachment_size
      expose :session_expire_delay
      expose :default_project_visibility
      expose :default_snippet_visibility
      expose :restricted_signup_domains
      expose :user_oauth_applications
      expose :after_sign_out_path
    end
  end
end
