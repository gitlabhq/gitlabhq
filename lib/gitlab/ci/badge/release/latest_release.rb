# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Release
      class LatestRelease < Badge::Base
        attr_reader :project, :release, :customization

        def initialize(project, current_user, opts: {})
          @project = project
          @customization = {
            key_width: opts[:key_width] ? opts[:key_width].to_i : nil,
            key_text: opts[:key_text],
            value_width: opts[:value_width] ? opts[:value_width].to_i : nil
          }

          # In the future, we should support `order_by=semver` for showing the
          # latest release based on Semantic Versioning.
          @release = ::ReleasesFinder.new(
            project,
            current_user,
            order_by_for_latest: opts[:order_by],
            latest: true).execute.first
        end

        def entity
          'Latest Release'
        end

        def tag
          @release&.tag
        end

        def metadata
          @metadata ||= Release::Metadata.new(self)
        end

        def template
          @template ||= Release::Template.new(self)
        end
      end
    end
  end
end
