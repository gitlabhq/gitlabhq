# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    class ForbiddenAction < StandardError; end

    class User
      attr_accessor :auth_hash, :gl_user

      def initialize(auth_hash)
        self.auth_hash = auth_hash
      end

      def persisted?
        gl_user.try(:persisted?)
      end

      def new?
        !persisted?
      end

      def valid?
        gl_user.try(:valid?)
      end

      def save
        unauthorized_to_create unless gl_user

        if needs_blocking?
          gl_user.save!
          gl_user.block
        else
          gl_user.save!
        end

        log.info "(OAuth) saving user #{auth_hash.email} from login with extern_uid => #{auth_hash.uid}"
        gl_user
      rescue ActiveRecord::RecordInvalid => e
        log.info "(OAuth) Error saving user: #{gl_user.errors.full_messages}"
        return self, e.record.errors
      end

      def gl_user
        @user ||= find_by_uid_and_provider

        if signup_enabled?
          @user ||= build_new_user
        end

        @user
      end

      protected

      def needs_blocking?
        new? && block_after_signup?
      end

      def signup_enabled?
        Gitlab.config.omniauth.allow_single_sign_on
      end

      def block_after_signup?
        Gitlab.config.omniauth.block_auto_created_users
      end

      def auth_hash=(auth_hash)
        @auth_hash = AuthHash.new(auth_hash)
      end

      def find_by_uid_and_provider
        identity = Identity.find_by(provider: auth_hash.provider, extern_uid: auth_hash.uid)
        identity && identity.user
      end

      def build_new_user
        user = ::User.new(user_attributes)
        user.skip_confirmation!
        user.identities.new(extern_uid: auth_hash.uid, provider: auth_hash.provider)
        user
      end

      def user_attributes
        {
          name: auth_hash.name,
          username: auth_hash.username,
          email: auth_hash.email,
          password: auth_hash.password,
          password_confirmation: auth_hash.password
        }
      end

      def log
        Gitlab::AppLogger
      end

      def unauthorized_to_create
        raise ForbiddenAction.new("Unauthorized to create user, signup disabled for #{auth_hash.provider}")
      end
    end
  end
end
