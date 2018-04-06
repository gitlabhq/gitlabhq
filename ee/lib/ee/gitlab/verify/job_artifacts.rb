module EE
  module Gitlab
    module Verify
      module JobArtifacts
        extend ::Gitlab::Utils::Override

        private

        override :relation
        def relation
          super.with_files_stored_locally
        end
      end
    end
  end
end
