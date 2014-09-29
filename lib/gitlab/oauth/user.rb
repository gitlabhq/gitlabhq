# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    class User
      class << self
        attr_reader :auth_hash

        def find(auth_hash)
          self.auth_hash = auth_hash
          find_by_uid_and_provider
        end

        def create(auth_hash)
          user = new(auth_hash)
          user.save_and_trigger_callbacks
        end

        def model
          ::User
        end

        def auth_hash=(auth_hash)
          @auth_hash = AuthHash.new(auth_hash)
        end

        protected
        def find_by_uid_and_provider
          model.where(provider: auth_hash.provider, extern_uid: auth_hash.uid).last
        end
      end

      # Instance methods
      attr_accessor :auth_hash, :user

      def initialize(auth_hash)
        self.auth_hash = auth_hash
        self.user = self.class.model.new(user_attributes)
        user.skip_confirmation!
      end

      def auth_hash=(auth_hash)
        @auth_hash = AuthHash.new(auth_hash)
      end

      def save_and_trigger_callbacks
        user.save!
        log.info "(OAuth) Creating user #{auth_hash.email} from login with extern_uid => #{auth_hash.uid}"
        user.block if needs_blocking?

        user
      rescue ActiveRecord::RecordInvalid => e
        log.info "(OAuth) Email #{e.record.errors[:email]}. Username #{e.record.errors[:username]}"
        return nil, e.record.errors
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
    end
  end
end
