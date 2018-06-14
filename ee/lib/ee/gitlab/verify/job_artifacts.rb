module EE
  module Gitlab
    module Verify
      module JobArtifacts
        extend ::Gitlab::Utils::Override

        private

        override :all_relation
        def all_relation
          super.with_files_stored_locally
        end
      end
    end
  end
end
