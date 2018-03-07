module EE
  module Gitlab
    module GithubImport
      module ParallelImporter
        extend ActiveSupport::Concern

        class_methods do
          def requires_ci_cd_setup?
            true
          end
        end
      end
    end
  end
end
