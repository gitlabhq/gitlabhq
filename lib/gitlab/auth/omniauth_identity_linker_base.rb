# frozen_string_literal: true

module Gitlab
  module Auth
    class OmniauthIdentityLinkerBase
      attr_reader :current_user, :oauth, :session

      def initialize(current_user, oauth, session = {})
        @current_user = current_user
        @oauth = oauth
        @changed = false
        @session = session
      end

      def link
        save if unlinked?
      end

      def changed?
        @changed
      end

      def failed?
        error_message.present?
      end

      # Require user authorization to link identity.
      # False by default, enabled in specific subclasses.
      def authorization_required?
        false
      end

      def error_message
        identity.validate

        identity.errors.full_messages.join(', ')
      end

      def provider
        oauth['provider']
      end

      def uid
        oauth['uid']
      end

      private

      def save
        @changed = identity.save
      end

      def unlinked?
        identity.new_record?
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def identity
        @identity ||= current_user.identities
                                  .with_extern_uid(provider, uid)
                                  .first_or_initialize(extern_uid: uid)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
