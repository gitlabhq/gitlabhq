# frozen_string_literal: true

module QA
  module Support
    module Helpers
      module ImportSource
        def self.enable(new_import_sources)
          current_import_sources = Runtime::ApplicationSettings.get_application_settings[:import_sources]

          import_sources = current_import_sources | Array(new_import_sources)

          return if (import_sources - current_import_sources).blank?

          Runtime::ApplicationSettings.set_application_settings(import_sources: import_sources)
        end
      end
    end
  end
end
