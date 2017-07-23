module QA
  module Runtime
    module User
      extend self

      def name
        ENV['GITLAB_USERNAME'] || 'root'
      end

      def password
        ENV['GITLAB_PASSWORD'] || 'test1234'
      end
    end
  end
end
