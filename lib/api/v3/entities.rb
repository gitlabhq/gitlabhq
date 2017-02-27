module API
  module V3
    module Entities
      class ProjectSnippet < Grape::Entity
        expose :id, :title, :file_name
        expose :author, using: ::API::Entities::UserBasic
        expose :updated_at, :created_at
        expose(:expires_at) { |snippet| nil }

        expose :web_url do |snippet, options|
          Gitlab::UrlBuilder.build(snippet)
        end
      end

      class Note < Grape::Entity
        expose :id
        expose :note, as: :body
        expose :attachment_identifier, as: :attachment
        expose :author, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :system?, as: :system
        expose :noteable_id, :noteable_type
        # upvote? and downvote? are deprecated, always return false
        expose(:upvote?)    { |note| false }
        expose(:downvote?)  { |note| false }
      end

      class Event < Grape::Entity
        expose :title, :project_id, :action_name
        expose :target_id, :target_type, :author_id
        expose :data, :target_title
        expose :created_at
        expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
        expose :author, using: ::API::Entities::UserBasic, if: ->(event, options) { event.author }

        expose :author_username do |event, options|
          event.author&.username
        end
      end

      class AwardEmoji < Grape::Entity
        expose :id
        expose :name
        expose :user, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :awardable_id, :awardable_type
      end

      class ApplicationSetting < Grape::Entity
        expose :id
        expose :default_projects_limit
        expose :signup_enabled
        expose :signin_enabled
        expose :gravatar_enabled
        expose :sign_in_text
        expose :after_sign_up_text
        expose :created_at
        expose :updated_at
        expose :home_page_url
        expose :default_branch_protection
        expose :restricted_visibility_levels
        expose :max_attachment_size
        expose :session_expire_delay
        expose :default_project_visibility
        expose :default_snippet_visibility
        expose :default_group_visibility
        expose :domain_whitelist
        expose :domain_blacklist_enabled
        expose :domain_blacklist
        expose :user_oauth_applications
        expose :after_sign_out_path
        expose :container_registry_token_expire_delay
        expose :repository_storage
        expose :repository_storages
        expose :koding_enabled
        expose :koding_url
        expose :plantuml_enabled
        expose :plantuml_url
        expose :terminal_max_session_time
      end
    end
  end
end
