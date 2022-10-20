# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Release
          include Gitlab::Utils::StrongMemoize

          attr_reader :release

          DESCRIPTION_LIMIT = 1024

          def initialize(release)
            @release = release
          end

          def variables
            strong_memoize(:variables) do
              ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
                next variables unless release

                if release.description
                  variables.append(
                    key: 'CI_RELEASE_DESCRIPTION',
                    value: release.description.truncate(DESCRIPTION_LIMIT),
                    raw: true)
                end
              end
            end
          end
        end
      end
    end
  end
end
