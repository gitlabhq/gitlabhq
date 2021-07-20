# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Concerns
          module FingerprintPathFromFile
            extend ActiveSupport::Concern

            def fingerprint_path
              File.basename(file_path.to_s)
            end
          end
        end
      end
    end
  end
end
