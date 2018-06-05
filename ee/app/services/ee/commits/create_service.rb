module EE
  module Commits
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :validate!
      def validate!
        super

        validate_repository_size!
      end

      def validate_repository_size!
        if project.above_size_limit?
          raise_error(Gitlab::RepositorySizeError.new(project).commit_error)
        end
      end
    end
  end
end
