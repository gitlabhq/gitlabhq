# frozen_string_literal: true

module Users
  class CreateService < BaseService
    include NewUserNotifier

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute
      reset_token = user.generate_reset_token if user.recently_sent_password_reset?

      create_user(user, reset_token)
    end

    private

    def user
      @user ||= build_class.new(current_user, params).execute
    end

    def after_create_hook(user, reset_token)
      notify_new_user(user, reset_token)
      grant_organization_admin_roles(user)
    end

    # The admin new-user form and the admin flag create the membership as owner
    # inside Users::BuildService, so no organization-user service ever sees it.
    # The worker decides whether an owner row written by the admin flag counts.
    def grant_organization_admin_roles(user)
      return unless ::Authz::Organizations::OwnerRoleSync.enabled?

      user.organization_users.owners.each do |organization_user|
        ::Authz::Organizations::GrantOwnerRoleWorker.perform_async(
          organization_user.organization_id, user.id, current_user.id)
      end
    end

    def build_class
      # overridden by inheriting classes
      Users::BuildService
    end

    def create_user(user, reset_token)
      return error(user.errors.full_messages.to_sentence, { user: user }) if user.errors.any?

      if user.save
        after_create_hook(user, reset_token)
        success({ user: user })
      else
        error(user.errors.full_messages.to_sentence, { user: user })
      end
    rescue Cells::TransactionRecord::Error
      error(user.errors.full_messages.to_sentence, { user: user })
    end

    def error(message, payload)
      ServiceResponse.error(message: message, payload: payload)
    end

    def success(payload)
      ServiceResponse.success(payload: payload)
    end
  end
end

Users::CreateService.prepend_mod_with('Users::CreateService')
