# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          def initialize(values, project, sha)
            @locations = Array(values.fetch(:include, []))
            @project = project
            @sha = sha
          end

          def process
            locations.map { |location| build_external_file(location) }
          end

          private

          attr_reader :locations, :project, :sha

          def build_external_file(location)
            if ::Gitlab::UrlSanitizer.valid?(location)
              External::File::Remote.new(location)
            else
              External::File::Local.new(location, project: project, sha: sha)
            end
          end
        end
      end
    end
  end
end
