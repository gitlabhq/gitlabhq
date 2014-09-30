# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    class User
      attr_accessor :auth_hash, :gl_user

      def initialize(auth_hash)
        self.auth_hash = auth_hash
      end

      def auth_hash=(auth_hash)
        @auth_hash = AuthHash.new(auth_hash)
      end

      def persisted?
        gl_user.persisted?
      end

      def new?
        !gl_user.persisted?
      end

      def valid?
        gl_user.valid?
      end

      def save
        gl_user.save!
        log.info "(OAuth) Creating user #{auth_hash.email} from login with extern_uid => #{auth_hash.uid}"
        gl_user.block if needs_blocking?

        gl_user
      rescue ActiveRecord::RecordInvalid => e
        log.info "(OAuth) Email #{e.record.errors[:email]}. Username #{e.record.errors[:username]}"
        return self, e.record.errors
      end

      def gl_user
        @user ||= find_by_uid_and_provider || build_new_user
      end

      def find_by_uid_and_provider
        model.where(provider: auth_hash.provider, extern_uid: auth_hash.uid).last
      end

      def build_new_user
        model.new(user_attributes).tap do |user|
          user.skip_confirmation!
        end
      end

      def user_attributes
        {
          extern_uid: auth_hash.uid,
          provider: auth_hash.provider,
          name: auth_hash.name,
          username: auth_hash.username,
          email: auth_hash.email,
          password: auth_hash.password,
          password_confirmation: auth_hash.password,
        }
      end

      def log
        Gitlab::AppLogger
      end

      def raise_error(message)
        raise OmniAuth::Error, "(OAuth) " + message
      end

      def needs_blocking?
        Gitlab.config.omniauth['block_auto_created_users']
      end

      def model
        ::User
      end
    end
  end
end
