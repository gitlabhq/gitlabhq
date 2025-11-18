# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module Header
          ##
          # This method just gets the files using the header-specific Matcher and verifies them.
          class Mapper < ::Gitlab::Ci::Config::External::Mapper
            private

            def get_files_and_verify_locations(locations)
              files = Header::Mapper::Matcher.new(context).process(locations)
              External::Mapper::Verifier.new(context).process(files)

              files
            end
          end
        end
      end
    end
  end
end
