# frozen_string_literal: true

module Users
  class SetNamespaceCommitEmailService
    include Gitlab::Allowable

    attr_reader :current_user, :target_user, :namespace, :email_id

    def initialize(current_user, namespace, email_id, params)
      @current_user = current_user
      @target_user = params.delete(:user) || current_user
      @namespace = namespace
      @email_id = email_id
    end

    def execute
      return error(_('Namespace must be provided.')) if namespace.nil?

      unless can?(current_user, :admin_user_email_address, target_user)
        return error(_("User doesn't exist or you don't have permission to change namespace commit emails."))
      end

      unless can?(target_user, :read_namespace, namespace)
        return error(_("Namespace doesn't exist or you don't have permission."))
      end

      email = target_user.emails.find_by(id: email_id) unless email_id.nil? # rubocop: disable CodeReuse/ActiveRecord
      existing_namespace_commit_email = target_user.namespace_commit_email_for_namespace(namespace)
      if existing_namespace_commit_email.nil?
        return error(_('Email must be provided.')) if email.nil?

        create_namespace_commit_email(email)
      elsif email_id.nil?
        remove_namespace_commit_email(existing_namespace_commit_email)
      else
        update_namespace_commit_email(existing_namespace_commit_email, email)
      end
    end

    private

    def remove_namespace_commit_email(namespace_commit_email)
      namespace_commit_email.destroy
      success(nil)
    end

    def create_namespace_commit_email(email)
      namespace_commit_email = ::Users::NamespaceCommitEmail.new(
        user: target_user,
        namespace: namespace,
        email: email
      )

      save_namespace_commit_email(namespace_commit_email)
    end

    def update_namespace_commit_email(namespace_commit_email, email)
      namespace_commit_email.email = email

      save_namespace_commit_email(namespace_commit_email)
    end

    def save_namespace_commit_email(namespace_commit_email)
      if !namespace_commit_email.save
        error_in_save(namespace_commit_email)
      else
        success(namespace_commit_email)
      end
    end

    def success(namespace_commit_email)
      ServiceResponse.success(payload: {
        namespace_commit_email: namespace_commit_email
      })
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def error_in_save(namespace_commit_email)
      return error(_('Failed to save namespace commit email.')) if namespace_commit_email.errors.empty?

      error(namespace_commit_email.errors.full_messages.to_sentence)
    end
  end
end
