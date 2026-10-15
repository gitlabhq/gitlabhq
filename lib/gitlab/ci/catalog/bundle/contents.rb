# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        class Contents < Data.define(:name, :version, :sha, :entry_path, :files)
          def file(path)
            files[path]
          end

          def identity
            [sha, entry_path]
          end
        end
      end
    end
  end
end
