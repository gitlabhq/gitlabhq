# frozen_string_literal: true

module API
  class Users < ::API::Base
    include PaginationParams
    include APIGuard
    include Helpers::CustomAttributes

    allow_access_with_scope :read_user, if: ->(request) { request.get? || request.head? }

    feature_category :user_profile,
      %w[
        /users/:id/custom_attributes
        /users/:id/custom_attributes/:key
        /users/:id/associations_count
      ]

    urgency :medium,
      %w[
        /users/:id/custom_attributes
        /users/:id/custom_attributes/:key
      ]

    resource :users, requirements: { uid: /[0-9]*/, id: /[0-9]*/ } do
      include CustomAttributesEndpoints

      before do
        authenticate_non_get!
        set_current_organization
      end

      helpers Helpers::UsersHelpers
      helpers Gitlab::Tracking::Helpers::WeakPasswordErrorEvent

      helpers do
        def custom_order_by_or_sort?
          params[:order_by].present? || params[:sort].present?
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def reorder_users(users)
          # Users#search orders by exact matches and handles pagination,
          # so we should prioritize that, unless the user specifies some custom
          # sort.
          if params[:search] && !custom_order_by_or_sort?
            users
          else
            params[:order_by] ||= 'id'
            params[:sort] ||= 'desc'
            users.reorder(order_options_with_tie_breaker)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        params :optional_attributes do
          optional :skype, type: String, desc: 'The Skype username'
          optional :linkedin, type: String, desc: 'The LinkedIn username'
          optional :twitter, type: String, desc: 'The Twitter username'
          optional :discord, type: String, desc: 'The Discord user ID'
          optional :website_url, type: String, desc: 'The website of the user'
          optional :organization, type: String, desc: 'The organization of the user'
          optional :projects_limit, type: Integer, desc: 'The number of projects a user can create'
          optional :extern_uid, type: String, desc: 'The external authentication provider UID'
          optional :provider, type: String, desc: 'The external provider'
          optional :bio, type: String, desc: 'The biography of the user'
          optional :location, type: String, desc: 'The location of the user'
          optional :pronouns, type: String, desc: 'The pronouns of the user'
          optional :public_email, type: String, desc: 'The public email of the user'
          optional :commit_email, type: String, desc: 'The commit email, _private for private commit email'
          optional :admin, type: Boolean, desc: 'Flag indicating the user is an administrator'
          optional :can_create_group, type: Boolean, desc: 'Flag indicating the user can create groups'
          optional :external, type: Boolean, desc: 'Flag indicating the user is an external user'
          optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for user', documentation: { type: 'file' }
          optional :theme_id, type: Integer, desc: 'The GitLab theme for the user'
          optional :color_scheme_id, type: Integer, desc: 'The color scheme for the file viewer'
          # TODO: Add `allow_blank: false` in 16.0. Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/387005
          optional :private_profile, type: Boolean, desc: 'Flag indicating the user has a private profile'
          optional :note, type: String, desc: 'Admin note for this user'
          optional :view_diffs_file_by_file, type: Boolean, desc: 'Flag indicating the user sees only one file diff per page'
          all_or_none_of :extern_uid, :provider

          use :optional_params_ee
        end

        params :sort_params do
          optional :order_by, type: String, values: %w[id name username created_at updated_at],
            default: 'id', desc: 'Return users ordered by a field'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
            desc: 'Return users sorted in ascending and descending order'
        end

        # Grape doesn't make it easy to tell whether a user supplied a
        # value for optional parameters with defaults. Disable the
        # defaults so that we can manually assign defaults if they are
        # not provided.
        params :sort_params_no_defaults do
          optional :order_by, type: String, values: %w[id name username created_at updated_at],
            desc: 'Return users ordered by a field'
          optional :sort, type: String, values: %w[asc desc],
            desc: 'Return users sorted in ascending and descending order'
        end
      end

      desc 'Get support PIN for a user. Available only for admins.' do
        detail 'This feature allows administrators to retrieve the support PIN for a specified user'
        success Entities::UserSupportPin
        is_array false
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      get ":id/support_pin", feature_category: :user_management do
        authenticated_as_admin!

        user = User.find_by_id(params[:id])
        not_found!('User') unless user

        begin
          result = ::Users::SupportPin::RetrieveService.new(user).execute
        rescue StandardError
          error!("Error retrieving Support PIN for user.", :unprocessable_entity)
        end

        if result
          present result, with: Entities::UserSupportPin
        else
          not_found!('Support PIN not found or expired')
        end
      end

      desc 'Get the list of users' do
        success Entities::UserBasic
      end
      params do
        # CE
        optional :username, type: String, desc: 'Get a single user with a specific username'
        optional :extern_uid, type: String, desc: 'Get a single user with a specific external authentication provider UID'
        optional :provider, type: String, desc: 'The external provider'
        optional :search, type: String, desc: 'Search for a username'
        optional :active, type: Boolean, default: false, desc: 'Filters only active users'
        optional :humans, type: Boolean, default: false, desc: 'Filters only human users'
        optional :external, type: Boolean, default: false, desc: 'Filters only external users'
        optional :blocked, type: Boolean, default: false, desc: 'Filters only blocked users'
        optional :created_after, type: DateTime, desc: 'Return users created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return users created before the specified time'
        optional :without_projects, type: Boolean, default: false, desc: 'Filters only users without projects'
        optional :without_project_bots, type: Boolean, default: false, desc: 'Filters users without project bots'
        optional :admins, type: Boolean, default: false, desc: 'Filters only admin users'
        optional :two_factor, type: String, desc: 'Filter users by Two-factor authentication.'
        optional :exclude_active, as: :without_active, type: Boolean, default: false, desc: 'Filters only non active users'
        optional :exclude_external, as: :non_external, type: Boolean, default: false, desc: 'Filters only non external users'
        optional :exclude_humans, as: :without_humans, type: Boolean, default: false, desc: 'Filters only non human users'
        optional :exclude_internal, as: :non_internal, type: Boolean, default: false, desc: 'Filters only non internal users'
        all_or_none_of :extern_uid, :provider

        use :sort_params_no_defaults
        use :pagination
        use :with_custom_attributes
        use :optional_index_params_ee
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get feature_category: :user_profile, urgency: :low do
        index_params = declared_params(include_missing: false)

        authenticated_as_admin! if index_params[:extern_uid].present? && index_params[:provider].present?

        unless current_user&.can_read_all_resources?
          index_params.except!(:created_after, :created_before, :order_by, :sort, :two_factor, :without_projects)
        end

        authorized = can?(current_user, :read_users_list)

        # When `current_user` is not present, require that the `username`
        # parameter is passed, to prevent an unauthenticated user from accessing
        # a list of all the users on the GitLab instance. `UsersFinder` performs
        # an exact match on the `username` parameter, so we are guaranteed to
        # get either 0 or 1 `users` here.
        authorized &&= index_params[:username].present? if current_user.blank?

        forbidden!("Not authorized to access /api/v4/users") unless authorized

        users = UsersFinder.new(current_user, index_params).execute
        users = reorder_users(users)

        entity = current_user&.can_read_all_resources? ? Entities::UserWithAdmin : Entities::UserBasic

        if entity == Entities::UserWithAdmin
          users = users.preload(:identities, :webauthn_registrations, :namespace, :followers, :followees, :user_preference, :user_detail)
        end

        users, options = with_custom_attributes(users, { with: entity, current_user: current_user })

        users = users.preload(:user_detail)

        present paginate_with_strategies(users), options
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a single user' do
        success Entities::User
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'

        use :with_custom_attributes
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ":id", feature_category: :user_profile, urgency: :low do
        forbidden!('Not authorized!') unless current_user

        unless current_user.can_read_all_resources?
          check_rate_limit!(:users_get_by_id,
            scope: current_user,
            users_allowlist: Gitlab::CurrentSettings.current_application_settings.users_get_by_id_limit_allowlist
          )
        end

        user = User.find_by(id: params[:id])

        not_found!('User') unless user && can?(current_user, :read_user, user)

        opts = { with: current_user.can_read_all_resources? ? Entities::UserDetailsWithAdmin : Entities::User, current_user: current_user }
        user, opts = with_custom_attributes(user, opts)

        present user, opts
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc "Get the status of a user"
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
      end
      get ":user_id/status", requirements: API::USER_REQUIREMENTS, feature_category: :user_profile, urgency: :default do
        if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
          check_rate_limit_by_user_or_ip!(:user_status)
        end

        user = find_user(params[:user_id])

        not_found!('User') unless user && can?(current_user, :read_user, user)

        present user.status || {}, with: Entities::UserStatus
      end

      desc 'Follow a user' do
        success Entities::User
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/follow', feature_category: :user_profile do
        user = find_user(params[:id])
        not_found!('User') unless user

        followee = current_user.follow(user)

        not_modified! unless followee

        if followee&.errors&.any?
          render_api_error!(followee.errors.full_messages.join(', '), 400)
        elsif followee&.persisted?
          present user, with: Entities::UserBasic
        end
      end

      desc 'Unfollow a user' do
        success Entities::User
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/unfollow', feature_category: :user_profile do
        user = find_user(params[:id])
        not_found!('User') unless user

        service_response = ::Users::UnfollowService.new(
          follower: current_user,
          followee: user
        ).execute

        if service_response.success?
          present user, with: Entities::UserBasic
        else
          not_modified!
        end
      end

      desc 'Get the users who follow a user' do
        success Entities::UserBasic
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/following', feature_category: :user_profile do
        forbidden!('Not authorized!') unless current_user

        unless current_user.can_read_all_resources?
          if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
            check_rate_limit_by_user_or_ip!(:user_following)
          end
        end

        user = find_user(params[:id])
        not_found!('User') unless user && can?(current_user, :read_user_profile, user)

        present paginate(user.followees), with: Entities::UserBasic
      end

      desc 'Get the followers of a user' do
        success Entities::UserBasic
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/followers', feature_category: :user_profile do
        forbidden!('Not authorized!') unless current_user

        unless current_user.can_read_all_resources?
          if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
            check_rate_limit_by_user_or_ip!(:user_followers)
          end
        end

        user = find_user(params[:id])
        not_found!('User') unless user && can?(current_user, :read_user_profile, user)

        present paginate(user.followers), with: Entities::UserBasic
      end

      desc 'Create a user. Available only for admins.' do
        success Entities::UserWithAdmin
      end
      params do
        requires :email, type: String, desc: 'The email of the user'
        optional :password, type: String, desc: 'The password of the new user'
        optional :reset_password, type: Boolean, desc: 'Flag indicating the user will be sent a password reset token'
        optional :skip_confirmation, type: Boolean, desc: 'Flag indicating the account is confirmed'
        at_least_one_of :password, :reset_password, :force_random_password
        requires :name, type: String, desc: 'The name of the user'
        requires :username, type: String, desc: 'The username of the user'
        optional :force_random_password, type: Boolean, desc: 'Flag indicating a random password will be set'
        use :optional_attributes
      end
      post feature_category: :user_profile do
        authenticated_as_admin!

        params = declared_params(include_missing: false).merge(organization_id: Current.organization&.id)

        # TODO: Remove in 16.0. Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/387005
        if params.key?(:private_profile) && params[:private_profile].nil?
          params[:private_profile] = Gitlab::CurrentSettings.user_defaults_to_private_profile
        end

        response = ::Users::AuthorizedCreateService.new(current_user, params).execute
        user = response.payload[:user]

        if response.success?
          present user, with: Entities::UserWithAdmin, current_user: current_user
        else
          conflict!('Email has already been taken') if User
            .by_any_email(user.email.downcase)
            .any?

          conflict!('Username has already been taken') if User
            .by_username(user.username)
            .any?

          track_weak_password_error(user, 'API::Users', 'create')

          render_validation_error!(user)
        end
      end

      desc 'Update a user. Available only for admins.' do
        success Entities::UserWithAdmin
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        optional :email, type: String, desc: 'The email of the user'
        optional :password, type: String, desc: 'The password of the new user'
        optional :skip_reconfirmation, type: Boolean, desc: 'Flag indicating the account skips the confirmation by email'
        optional :name, type: String, desc: 'The name of the user'
        optional :username, type: String, desc: 'The username of the user'
        use :optional_attributes
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ":id", feature_category: :user_profile do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        conflict!('Email has already been taken') if params[:email] &&
          User.by_any_email(params[:email].downcase)
              .where.not(id: user.id).exists?

        conflict!('Username has already been taken') if params[:username] &&
          User.by_username(params[:username])
              .where.not(id: user.id).exists?

        user_params = declared_params(include_missing: false)

        # TODO: Remove in 16.0. Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/387005
        if user_params.key?(:private_profile) && user_params[:private_profile].nil?
          user_params[:private_profile] = Gitlab::CurrentSettings.user_defaults_to_private_profile
        end

        admin_making_changes_for_another_user = (current_user != user)

        if user_params[:password].present?
          user_params[:password_expires_at] = Time.current if admin_making_changes_for_another_user
        end

        result = ::Users::UpdateService.new(current_user, user_params.merge(user: user)).execute do |user|
          user.send_only_admin_changed_your_password_notification! if admin_making_changes_for_another_user
        end

        if result[:status] == :success
          present user, with: Entities::UserWithAdmin, current_user: current_user
        else
          track_weak_password_error(user, 'API::Users', 'update')
          render_validation_error!(user)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc "Disable two factor authentication for a user. Available only for admins" do
        detail 'This feature was added in GitLab 15.2'
        success Entities::UserWithAdmin
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      patch ":id/disable_two_factor", feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by_id(params[:id])
        not_found!('User') unless user

        # We're disabling Cop/UserAdmin because it checks if the given user (not the current user) is an admin.
        forbidden!('Two-factor authentication for admins cannot be disabled via the API. Use the Rails console') if user.admin? # rubocop:disable Cop/UserAdmin

        result = TwoFactor::DestroyService.new(current_user, user: user).execute

        if result[:status] == :success
          no_content!
        else
          bad_request!(result[:message])
        end
      end

      desc "Delete a user's identity. Available only for admins" do
        success Entities::UserWithAdmin
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :provider, type: String, desc: 'The external provider'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/identities/:provider", feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        identity = user.identities.find_by(provider: params[:provider])
        not_found!('Identity') unless identity

        destroy_conditionally!(identity)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get the project-level Deploy keys that a specified user can access to.' do
        success Entities::DeployKey
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :pagination
      end
      get ':user_id/project_deploy_keys', requirements: API::USER_REQUIREMENTS, feature_category: :continuous_delivery do
        user = find_user(params[:user_id])
        not_found!('User') unless user && can?(current_user, :read_user, user)

        project_ids = Project.visible_to_user_and_access_level(current_user, Gitlab::Access::MAINTAINER)

        unless current_user == user
          # Restrict to only common projects of both current_user and user.
          project_ids = project_ids.visible_to_user_and_access_level(user, Gitlab::Access::MAINTAINER)
        end

        forbidden!('No common authorized project found') unless project_ids.present?

        keys = DeployKey.in_projects(project_ids)
        present paginate(keys), with: Entities::DeployKey
      end

      desc 'Add an SSH key to a specified user. Available only for admins.' do
        success Entities::SSHKey
      end
      params do
        requires :user_id, type: Integer, desc: 'The ID of the user'
        requires :key, type: String, desc: 'The new SSH key'
        requires :title, type: String, desc: 'The title of the new SSH key'
        optional :expires_at, type: DateTime, desc: 'The expiration date of the SSH key in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
        optional :usage_type, type: String, values: Key.usage_types.keys, default: 'auth_and_signing',
          desc: 'Scope of usage for the SSH key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ":user_id/keys", feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:user_id))
        not_found!('User') unless user

        key = ::Keys::CreateService.new(current_user, declared_params(include_missing: false).merge(user: user)).execute

        if key.persisted?
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get the SSH keys of a specified user.' do
        success Entities::SSHKey
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :pagination
      end
      get ':user_id/keys', requirements: API::USER_REQUIREMENTS, feature_category: :system_access do
        if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
          check_rate_limit_by_user_or_ip!(:user_keys)
        end

        user = find_user(params[:user_id])
        not_found!('User') unless user && can?(current_user, :read_user, user)

        keys = user.keys.preload_users
        present paginate(keys), with: Entities::SSHKey
      end

      desc 'Get a SSH key of a specified user.' do
        success Entities::SSHKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      get ':id/keys/:key_id', requirements: API::USER_REQUIREMENTS, feature_category: :system_access do
        if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
          check_rate_limit_by_user_or_ip!(:user_specific_key)
        end

        user = find_user(params[:id])
        not_found!('User') unless user && can?(current_user, :read_user, user)

        key = user.keys.find_by(id: params[:key_id]) # rubocop: disable CodeReuse/ActiveRecord
        not_found!('Key') unless key

        present key, with: Entities::SSHKey
      end

      desc 'Delete an existing SSH key from a specified user. Available only for admins.' do
        success Entities::SSHKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/keys/:key_id', feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        destroy_conditionally!(key) do |key|
          destroy_service = ::Keys::DestroyService.new(current_user)
          destroy_service.execute(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Add a GPG key to a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GpgKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key, type: String, desc: 'The new GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/gpg_keys', feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        key = ::GpgKeys::CreateService.new(user, declared_params(include_missing: false)).execute

        if key.persisted?
          present key, with: Entities::GpgKey
        else
          render_validation_error!(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get the GPG keys of a specified user.' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GpgKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/gpg_keys', feature_category: :system_access do
        if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
          check_rate_limit_by_user_or_ip!(:user_gpg_keys)
        end

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present paginate(user.gpg_keys), with: Entities::GpgKey
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a specific GPG key for a given user.' do
        detail 'This feature was added in GitLab 13.5'
        success Entities::GpgKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/gpg_keys/:key_id', feature_category: :system_access do
        if Feature.enabled?(:rate_limiting_user_endpoints, ::Feature.current_request)
          check_rate_limit_by_user_or_ip!(:user_specific_gpg_key)
        end

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        present key, with: Entities::GpgKey
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete an existing GPG key from a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/gpg_keys/:key_id', feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        destroy_conditionally!(key) do |key|
          destroy_service = ::GpgKeys::DestroyService.new(current_user)
          destroy_service.execute(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Revokes an existing GPG key from a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/gpg_keys/:key_id/revoke', feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        key.revoke
        status :accepted
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Add an email address to a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :email, type: String, desc: 'The email of the user'
        optional :skip_confirmation, type: Boolean, desc: 'Skip confirmation of email and assume it is verified'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ":id/emails", feature_category: :user_profile do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        email = Emails::CreateService.new(current_user, declared_params(include_missing: false).merge(user: user)).execute

        if email.errors.blank?
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get the emails addresses of a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/emails', feature_category: :user_profile do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present paginate(user.emails), with: Entities::Email
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete an email address of a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/emails/:email_id', feature_category: :user_profile do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        email = user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        destroy_conditionally!(email) do |email|
          Emails::DestroyService.new(current_user, user: user).execute(email)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete a user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        optional :hard_delete, type: Boolean, desc: "Whether to remove a user's contributions"
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id", feature_category: :user_profile do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user
        conflict!('User cannot be removed while is the sole-owner of a group') unless user.can_be_removed? || params[:hard_delete]

        destroy_conditionally!(user) do
          user.delete_async(deleted_by: current_user, params: params)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Activate a deactivated user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/activate', feature_category: :system_access do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        result = ::Users::ActivateService.new(current_user).execute(user)
        if result[:status] == :success
          true
        else
          render_api_error!(result[:message], result[:reason] || :bad_request)
        end
      end

      desc 'Approve a pending user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/approve', feature_category: :system_access do
        user = User.find_by(id: params[:id])
        not_found!('User') unless can?(current_user, :read_user, user)

        result = ::Users::ApproveService.new(current_user).execute(user)

        if result[:success]
          result
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Reject a pending user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/reject', feature_category: :system_access do
        user = find_user_by_id(params)

        result = ::Users::RejectService.new(current_user).execute(user)

        if result[:success]
          present user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      # rubocop: enable CodeReuse/ActiveRecord
      desc 'Deactivate an active user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/deactivate', feature_category: :system_access do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        break if user.deactivated?

        result = ::Users::DeactivateService.new(current_user, skip_authorization: true).execute(user)
        if result[:status] == :success
          true
        else
          render_api_error!(result[:message], result[:reason] || :bad_request)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Block a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/block', feature_category: :system_access do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if user.ldap_blocked?
          forbidden!('LDAP blocked users cannot be modified by the API')
        elsif current_user == user
          forbidden!('The API initiating user cannot be blocked by the API')
        end

        break if user.blocked?

        result = ::Users::BlockService.new(current_user).execute(user)
        if result[:status] == :success
          true
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Unblock a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/unblock', feature_category: :system_access do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if user.ldap_blocked?
          forbidden!('LDAP blocked users cannot be unblocked by the API')
        elsif user.deactivated?
          forbidden!('Deactivated users cannot be unblocked by the API')
        else
          result = ::Users::UnblockService.new(current_user).execute(user)
          result.success?
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Ban a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/ban', feature_category: :system_access do
        authenticated_as_admin!
        user = find_user_by_id(params)

        result = ::Users::BanService.new(current_user).execute(user)
        if result[:status] == :success
          true
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Unban a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/unban', feature_category: :system_access do
        authenticated_as_admin!
        user = find_user_by_id(params)

        result = ::Users::UnbanService.new(current_user).execute(user)
        if result[:status] == :success
          true
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Get memberships' do
        success Entities::Membership
      end
      params do
        requires :user_id, type: Integer, desc: 'The ID of the user'
        optional :type, type: String, values: %w[Project Namespace]
        use :pagination
      end
      get ":user_id/memberships", feature_category: :user_profile, urgency: :high do
        authenticated_as_admin!
        user = find_user_by_id(params)

        members = case params[:type]
                  when 'Project'
                    user.project_members
                  when 'Namespace'
                    user.group_members
                  else
                    user.members
                  end

        members = members.including_source

        present paginate(members), with: Entities::Membership
      end

      resources ':id/associations_count' do
        helpers do
          def present_entity(result)
            present result,
              with: ::API::Entities::UserAssociationsCount
          end
        end

        desc "Returns a list of a specified user's count of projects, groups, issues and merge requests."
        params do
          requires :id,
            type: Integer,
            desc: 'ID of the user to query.'
        end
        get do
          authenticate!

          user = find_user_by_id(params)
          forbidden! unless can?(current_user, :get_user_associations_count, user)
          not_found!('User') unless user

          present_entity(user)
        end
      end

      params do
        requires :user_id, type: Integer, desc: 'The ID of the user'
      end
      segment ':user_id' do
        resource :impersonation_tokens do
          helpers do
            def finder(options = {})
              user = find_user_by_id(params)
              PersonalAccessTokensFinder.new({ user: user, impersonation: true }.merge(options))
            end

            def find_impersonation_token
              finder.find_by_id(declared_params[:impersonation_token_id]) || not_found!('Impersonation Token')
            end
          end

          before { authenticated_as_admin! }

          desc 'Retrieve impersonation tokens. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationToken
          end
          params do
            use :pagination
            optional :state, type: String, default: 'all', values: %w[all active inactive], desc: 'Filters (all|active|inactive) impersonation_tokens'
          end
          get feature_category: :system_access do
            present paginate(finder(declared_params(include_missing: false)).execute), with: Entities::ImpersonationToken
          end

          desc 'Create a impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationTokenWithToken
          end
          params do
            requires :name, type: String, desc: 'The name of the impersonation token'
            optional :description, type: String, desc: 'The description of the personal access token'
            optional :expires_at, type: Date, desc: 'The expiration date in the format YEAR-MONTH-DAY of the impersonation token'
            optional :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The array of scopes of the impersonation token'
          end
          post feature_category: :system_access do
            impersonation_token = finder.build(declared_params(include_missing: false))
            impersonation_token.organization = Current.organization

            if impersonation_token.save
              present impersonation_token, with: Entities::ImpersonationTokenWithToken
            else
              render_validation_error!(impersonation_token)
            end
          end

          desc 'Retrieve impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationToken
          end
          params do
            requires :impersonation_token_id, type: Integer, desc: 'The ID of the impersonation token'
          end
          get ':impersonation_token_id', feature_category: :system_access do
            present find_impersonation_token, with: Entities::ImpersonationToken
          end

          desc 'Revoke a impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
          end
          params do
            requires :impersonation_token_id, type: Integer, desc: 'The ID of the impersonation token'
          end
          delete ':impersonation_token_id', feature_category: :system_access do
            token = find_impersonation_token

            destroy_conditionally!(token) do
              token.revoke!
            end
          end
        end

        resource :personal_access_tokens do
          helpers do
            def target_user
              find_user_by_id(params)
            end
          end

          before { authenticated_as_admin! }

          desc 'Create a personal access token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 13.6'
            success Entities::PersonalAccessTokenWithToken
          end
          params do
            requires :name, type: String, desc: 'The name of the personal access token'
            requires :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, values: ::Gitlab::Auth.all_available_scopes.map(&:to_s),
              desc: 'The array of scopes of the personal access token'
            optional :description, type: String, desc: 'The description of the personal access token'
            optional :expires_at, type: Date, desc: 'The expiration date in the format YEAR-MONTH-DAY of the personal access token'
          end
          post feature_category: :system_access do
            response = ::PersonalAccessTokens::CreateService.new(
              current_user: current_user, target_user: target_user, organization_id: Current.organization_id, params: declared_params(include_missing: false)
            ).execute

            if response.success?
              present response.payload[:personal_access_token], with: Entities::PersonalAccessTokenWithToken
            else
              render_api_error!(response.message, response.http_status || :unprocessable_entity)
            end
          end
        end
      end
    end

    resource :user do
      before do
        authenticate!
        set_current_organization
      end

      # Enabling /user endpoint for the v3 version to allow oauth
      # authentication through this endpoint.
      version %w[v3 v4], using: :path do
        desc 'Get the currently authenticated user' do
          success Entities::UserPublic
        end
        get feature_category: :user_profile, urgency: :low do
          entity =
            # We're disabling Cop/UserAdmin because it checks if the given user is an admin.
            if current_user.admin? # rubocop:disable Cop/UserAdmin
              Entities::UserWithAdmin
            else
              Entities::UserPublic
            end

          present current_user, with: entity, current_user: current_user
        end
      end

      helpers do
        def set_user_status(include_missing_params:)
          forbidden! unless can?(current_user, :update_user_status, current_user)

          if ::Users::SetStatusService.new(current_user, declared_params(include_missing: include_missing_params)).execute
            present current_user.status, with: Entities::UserStatus
          else
            render_validation_error!(current_user.status)
          end
        end

        params :set_user_status_params do
          optional :emoji, type: String, desc: "The emoji to set on the status"
          optional :message, type: String, desc: "The status message to set"
          optional :availability, type: String, desc: "The availability of user to set"
          optional :clear_status_after, type: String, desc: "Automatically clear emoji, message and availability fields after a certain time", values: UserStatus::CLEAR_STATUS_QUICK_OPTIONS.keys
        end
      end

      desc "Get the currently authenticated user's SSH keys" do
        success Entities::SSHKey
      end
      params do
        use :pagination
      end
      get "keys", feature_category: :system_access do
        keys = current_user.keys.preload_users

        present paginate(keys), with: Entities::SSHKey
      end

      desc 'Get a single key owned by currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get "keys/:key_id", feature_category: :system_access do
        key = current_user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        present key, with: Entities::SSHKey
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Add a new SSH key to the currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key, type: String, desc: 'The new SSH key'
        requires :title, type: String, desc: 'The title of the new SSH key'
        optional :expires_at, type: DateTime, desc: 'The expiration date of the SSH key in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
        optional :usage_type, type: String, values: Key.usage_types.keys, default: 'auth_and_signing',
          desc: 'Scope of usage for the SSH key'
      end
      post "keys", feature_category: :system_access do
        key = ::Keys::CreateService.new(current_user, declared_params(include_missing: false)).execute

        if key.persisted?
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Delete an SSH key from the currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete "keys/:key_id", feature_category: :system_access do
        key = current_user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        destroy_conditionally!(key) do |key|
          destroy_service = ::Keys::DestroyService.new(current_user)
          destroy_service.execute(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc "Get the currently authenticated user's GPG keys" do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GpgKey
      end
      params do
        use :pagination
      end
      get 'gpg_keys', feature_category: :system_access do
        present paginate(current_user.gpg_keys), with: Entities::GpgKey
      end

      desc 'Get a single GPG key owned by currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GpgKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get 'gpg_keys/:key_id', feature_category: :system_access do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        present key, with: Entities::GpgKey
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Add a new GPG key to the currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GpgKey
      end
      params do
        requires :key, type: String, desc: 'The new GPG key'
      end
      post 'gpg_keys', feature_category: :system_access do
        key = ::GpgKeys::CreateService.new(current_user, declared_params(include_missing: false)).execute

        if key.persisted?
          present key, with: Entities::GpgKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Revoke a GPG key owned by currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post 'gpg_keys/:key_id/revoke', feature_category: :system_access do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        key.revoke
        status :accepted
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete a GPG key from the currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete 'gpg_keys/:key_id', feature_category: :system_access do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        destroy_conditionally!(key) do |key|
          destroy_service = ::GpgKeys::DestroyService.new(current_user)
          destroy_service.execute(key)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc "Get the currently authenticated user's email addresses" do
        success Entities::Email
      end
      params do
        use :pagination
      end
      get "emails", feature_category: :user_profile, urgency: :high do
        present paginate(current_user.emails), with: Entities::Email
      end

      desc "[DEPRECATED] Update a user's credit_card_validation" do
        success Entities::UserCreditCardValidations
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        requires :credit_card_validated_at, type: DateTime, desc: 'The time when the user\'s credit card was validated'
        requires :credit_card_expiration_month, type: Integer, desc: 'The month the credit card expires'
        requires :credit_card_expiration_year, type: Integer, desc: 'The year the credit card expires'
        requires :credit_card_holder_name, type: String, desc: 'The credit card holder name'
        requires :credit_card_mask_number, type: String, desc: 'The last 4 digits of credit card number'
        requires :credit_card_type, type: String, desc: 'The credit card network name'

        optional :zuora_payment_method_xid, type: String, desc: 'The Zuora payment method ID'
        optional :stripe_setup_intent_xid, type: String, desc: 'The Stripe setup intent ID'
        optional :stripe_payment_method_xid, type: String, desc: 'The Stripe payment method ID'
        optional :stripe_card_fingerprint, type: String, desc: 'The Stripe credit card fingerprint'
      end
      put ":user_id/credit_card_validation", urgency: :low, feature_category: :subscription_management do
        authenticated_as_admin!

        user = find_user(params[:user_id])
        not_found!('User') unless user

        attrs = declared_params(include_missing: false)

        service = ::Users::UpsertCreditCardValidationService.new(attrs).execute

        if service.success?
          present user.credit_card_validation, with: Entities::UserCreditCardValidations
        elsif service.reason == :rate_limited
          render_api_error!(service.message, 400)
        else
          bad_request!
        end
      end

      desc 'Create a new Support PIN for the authenticated user' do
        detail 'This feature creates a temporary Support PIN for the authenticated user'
        success Entities::UserSupportPin
      end
      post "support_pin", feature_category: :user_profile do
        authenticate!

        result = ::Users::SupportPin::UpdateService.new(current_user).execute

        if result[:status] == :success
          present({ pin: result[:pin], expires_at: result[:expires_at] }, with: Entities::UserSupportPin)
        else
          error!(result[:message], :unprocessable_entity)
        end
      end

      desc 'Get the current Support PIN for the authenticated user' do
        detail 'This feature retrieves the temporary Support PIN for the authenticated user'
        success Entities::UserSupportPin
      end
      get "support_pin", feature_category: :user_profile do
        authenticate!

        result = ::Users::SupportPin::RetrieveService.new(current_user).execute

        if result
          # Convert the Time object to ISO 8601 format
          expires_at = result[:expires_at].iso8601

          present({ pin: result[:pin], expires_at: expires_at }, with: Entities::UserSupportPin)
        else
          not_found!('Support PIN not found or expired')
        end
      end

      desc "Update the current user's preferences" do
        success Entities::UserPreferences
        detail 'This feature was introduced in GitLab 13.10.'
      end
      params do
        optional :view_diffs_file_by_file, type: Boolean, desc: 'Flag indicating the user sees only one file diff per page'
        optional :show_whitespace_in_diffs, type: Boolean, desc: 'Flag indicating the user sees whitespace changes in diffs'
        optional :pass_user_identities_to_ci_jwt, type: Boolean, desc: 'Flag indicating the user passes their external identities to a CI job as part of a JSON web token.'
        at_least_one_of :view_diffs_file_by_file, :show_whitespace_in_diffs, :pass_user_identities_to_ci_jwt
      end
      put "preferences", feature_category: :user_profile, urgency: :high do
        authenticate!

        preferences = current_user.user_preference

        attrs = declared_params(include_missing: false)

        bad_request! unless attrs

        service = ::UserPreferences::UpdateService.new(current_user, attrs).execute
        if service.success?
          present preferences, with: Entities::UserPreferences
        else
          bad_request!
        end
      end

      desc "Get the current user's preferences" do
        success Entities::UserPreferences
        detail 'This feature was introduced in GitLab 14.0.'
      end
      get "preferences", feature_category: :user_profile do
        present current_user.user_preference, with: Entities::UserPreferences
      end

      desc 'Get a single email address owned by the currently authenticated user' do
        success Entities::Email
      end
      params do
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get "emails/:email_id", feature_category: :user_profile do
        email = current_user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        present email, with: Entities::Email
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Add new email address to the currently authenticated user' do
        success Entities::Email
      end
      params do
        requires :email, type: String, desc: 'The new email'
      end
      post "emails", feature_category: :user_profile do
        email = Emails::CreateService.new(current_user, declared_params.merge(user: current_user)).execute

        if email.errors.blank?
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end

      desc 'Delete an email address from the currently authenticated user'
      params do
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete "emails/:email_id", feature_category: :user_profile do
        email = current_user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        destroy_conditionally!(email) do |email|
          Emails::DestroyService.new(current_user, user: current_user).execute(email)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a list of user activities'
      params do
        optional :from, type: DateTime, default: 6.months.ago, desc: 'Date string in the format YEAR-MONTH-DAY'
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get "activities", feature_category: :user_profile do
        activities = User
          .where(User.arel_table[:last_activity_on].gteq(params[:from]))
          .reorder(last_activity_on: :asc)

        activities = activities.with_public_profile unless current_user.can_read_all_resources?

        present paginate(activities), with: Entities::UserActivity
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Set the status of the current user' do
        success Entities::UserStatus
        detail 'Any parameters that are not passed will be nullified.'
      end
      params do
        use :set_user_status_params
      end
      put "status", feature_category: :user_profile do
        set_user_status(include_missing_params: true)
      end

      desc 'Set the status of the current user' do
        success Entities::UserStatus
        detail 'Any parameters that are not passed will be ignored.'
      end
      params do
        use :set_user_status_params
      end
      patch "status", feature_category: :user_profile do
        if declared_params(include_missing: false).empty?
          status :ok

          break
        end

        set_user_status(include_missing_params: false)
      end

      desc 'get the status of the current user' do
        success Entities::UserStatus
      end
      get 'status', feature_category: :user_profile do
        present current_user.status || {}, with: Entities::UserStatus
      end

      desc 'Set the avatar of the current user' do
        success Entities::Avatar
        detail 'This feature was introduced in GitLab 17.0.'
      end
      params do
        requires :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'The avatar file (generated by Multipart middleware)', documentation: { type: 'file' }
      end
      put "avatar", feature_category: :user_profile do
        update_params = {
          avatar: declared_params[:avatar],
          user: current_user
        }
        result = ::Users::UpdateService.new(current_user, update_params).execute

        if result[:status] == :success
          present current_user, with: Entities::Avatar
        else
          render_api_error!(result[:message], result[:reason] || :bad_request)
        end
      end

      resource :personal_access_tokens do
        desc 'Create a personal access token with limited scopes for the currently authenticated user' do
          detail 'This feature was introduced in GitLab 16.5'
          success Entities::PersonalAccessTokenWithToken
        end
        params do
          requires :name, type: String, desc: 'The name of the personal access token'
          # NOTE: for security reasons only the k8s_proxy scope is allowed at the moment.
          # See details in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923#note_1571272897
          # and in https://gitlab.com/gitlab-org/gitlab/-/issues/425171
          requires :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, values: [::Gitlab::Auth::K8S_PROXY_SCOPE].map(&:to_s),
            desc: 'The array of scopes of the personal access token'
          optional :description, type: String, desc: 'The description of the personal access token'
          optional :expires_at, type: Date, default: -> { 1.day.from_now.to_date }, desc: 'The expiration date in the format YEAR-MONTH-DAY of the personal access token'
        end
        post feature_category: :system_access do
          response = ::PersonalAccessTokens::CreateService.new(
            current_user: current_user, target_user: current_user, params: declared_params(include_missing: false), organization_id: Current.organization_id
          ).execute

          if response.success?
            present response.payload[:personal_access_token], with: Entities::PersonalAccessTokenWithToken
          else
            render_api_error!(response.message, response.http_status || :unprocessable_entity)
          end
        end
      end
    end
  end
end

API::Users.prepend_mod
