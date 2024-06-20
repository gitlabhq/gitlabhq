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
        query = <<~GQL
          mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) {
            designManagementUpload(input: { files: $files, projectPath: $projectPath, iid: $iid }) {
              designs {
                id
                fullPath
                image
                filename
                webUrl
              }
            }
          }
        GQL
        operations = {
          query: query,
          variables: {
            files: nil,
            projectPath: issue.project.full_path,
            iid: issue.iid
          }
        }

        {
          operations: JSON.dump(operations),
          map: '{"0":["variables.files"]}',
          "0": ::File.new(filepath)
        }
      end

      # Override api_post_to method to add multipart request option
      #
      # @param [String] post_path
      # @param [Hash] post_body
      # @param [Hash] args
      # @return [Hash]
      def api_post_to(post_path, post_body, args = {})
        super(post_path, post_body, { content_type: 'multipart/form-data' })
      end

      # Return first design from fabricated design array
      # designManagementUpload mutation doesn't support returning single design
      #
      # @param [Hash] api_resource
      # @return [Hash]
      def transform_api_resource(api_resource)
        api_resource.key?(:designs) ? api_resource[:designs].first : api_resource
      end

      def process_api_response(parsed_response)
        design_response = if parsed_response.key?(:designs)
                            response = parsed_response
                            response[:designs].each do |design|
                              design[:id] = extract_graphql_id(design)
                            end
                            response
                          elsif parsed_response.key?(:design_collection)
                            response = parsed_response[:design_collection][:design]
                            response[:id] = extract_graphql_id(response)
                            response
                          else
                            parsed_response
                          end

        super(design_response)
      end

      private

      def filepath
        Runtime::Path.fixture('designs', filename)
      end
    end
  end
end
