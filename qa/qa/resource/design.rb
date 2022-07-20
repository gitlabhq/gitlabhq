# frozen_string_literal: true

module QA
  module Resource
    class Design < Base
      attribute :issue do
        Issue.fabricate_via_api!
      end

      attributes :id,
                 :filename,
                 :full_path,
                 :image

      def initialize
        @update = false
        @filename = 'banana_sample.gif'
      end

      def fabricate!
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.add_design(filepath)
        end
      end

      def api_get_path
        '/graphql'
      end

      alias_method :api_post_path, :api_get_path

      # Fetch design
      #
      # @return [Hash]
      def api_get
        process_api_response(
          api_post_to(
            api_get_path,
            <<~GQL
                query {
                  issue(id: "gid://gitlab/Issue/#{issue.id}") {
                    designCollection {
                      design(filename: "#{filename}") {
                        id
                        fullPath
                        image
                        filename
                      }
                    }
                  }
                }
            GQL
          )
        )
      end

      # Graphql mutation for design creation
      #
      # @return [String]
      def api_post_body
        # TODO: design creation requires file upload via multipart/form-data request type with file passed in mutation
        # which currently isn't supported by our api implementation
        # https://gitlab.com/gitlab-org/gitlab/-/issues/366592
        raise NotImplementedError, "File uploads are not supported"
      end

      private

      def filepath
        ::File.absolute_path(::File.join('qa', 'fixtures', 'designs', filename))
      end
    end
  end
end
