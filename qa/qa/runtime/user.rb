module QA
  module Runtime
    module User
      extend self

      def name
        ENV['GITLAB_USERNAME'] || 'root'
      end

      def password
        ENV['GITLAB_PASSWORD'] || '5iveL!fe'
      end
    end
  end
end
