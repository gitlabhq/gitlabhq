module QA
  module Runtime
    module User
      extend self

      def name
        Runtime::Env.user_username || 'root'
      end

      def password
        Runtime::Env.user_password || '5iveL!fe'
      end
    end
  end
end
