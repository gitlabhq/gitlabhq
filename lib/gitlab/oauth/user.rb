# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    class User
      class << self
        attr_reader :auth

        def find(auth)
          @auth = auth
          find_by_uid_and_provider
        end

        def create(auth)
          @auth = auth
          user = new(auth).user

          user.save!
          log.info "(OAuth) Creating user #{email} from login with extern_uid => #{uid}"
          user.block if needs_blocking?

          user
        rescue ActiveRecord::RecordInvalid => e
          log.info "(OAuth) Email #{e.record.errors[:email]}. Username #{e.record.errors[:username]}"
          return nil, e.record.errors
        end

        private

        def find_by_uid_and_provider
          ::User.where(provider: provider, extern_uid: uid).last
        end

        def provider
          auth.provider
        end

        def uid
          auth.uid.to_s
        end

        def needs_blocking?
          Gitlab.config.omniauth['block_auto_created_users']
        end
      end

      attr_accessor :auth, :user

      def initialize(auth)
        self.auth = auth
        self.user = ::User.new(user_attributes)
        user.skip_confirmation!
      end

      def user_attributes
        {
          extern_uid: uid,
          provider: provider,
          name: name,
          username: username,
          email: email,
          password: password,
          password_confirmation: password,
        }
      end

      def uid
        auth.uid.to_s
      end

      def provider
        auth.provider
      end

      def info
        auth.info
      end

      def name
        (info.name || full_name).to_s.force_encoding('utf-8')
      end

      def full_name
        "#{info.first_name} #{info.last_name}"
      end

      def username
        (info.try(:nickname) || generate_username).to_s.force_encoding('utf-8')
      end

      def email
        (info.try(:email) || generate_temporarily_email).downcase
      end

      def password
        @password ||= Devise.friendly_token[0, 8].downcase
      end

      def log
        Gitlab::AppLogger
      end

      def raise_error(message)
        raise OmniAuth::Error, "(OAuth) " + message
      end

      # Get the first part of the email address (before @)
      # In addtion in removes illegal characters
      def generate_username
        email.match(/^[^@]*/)[0].parameterize
      end

      def generate_temporarily_email
        "temp-email-for-oauth-#{username}@gitlab.localhost"
      end
    end
  end
end
