# frozen_string_literal: true

module QA
  module Tools
    module Lib
      module Project
        def delete_projects(project_ids, api_client, dry_run = false)
          if dry_run
            $stdout.puts "Following #{project_ids.length} projects would be deleted:"
          else
            $stdout.puts "Deleting #{project_ids.length} projects..."
          end

          project_ids.each do |project_id|
            request_url = Runtime::API::Request.new(api_client, "/projects/#{project_id}").url
            parsed_body = parse_body(get(request_url))
            path = parsed_body[:path_with_namespace]
            created_at = parsed_body[:created_at]

            if dry_run
              $stdout.puts "#{path} - created at: #{created_at}"
            else
              $stdout.puts "\nDeleting project #{path} - created at: #{created_at}"
              delete_response = delete(request_url)
              dot_or_f = delete_response.code.between?(200, 300) ? "\e[32m.\e[0m" : "\e[31mF - #{delete_response}\e[0m"
              print dot_or_f
            end
          end
        end

        # Extracts project ID from resource
        #
        # @param [Hash] resource Project resource
        # @return [String, nil] Project ID or nil if not found
        def extract_project_id(resource)
          # Try different ways to get project ID
          project_id = resource[:id] ||
            resource['id'] ||
            resource[:api_path]&.match(%r{/projects/(\d+)})&.[](1) ||
            resource['api_path']&.match(%r{/projects/(\d+)})&.[](1)

          unless project_id
            logger.error("Could not extract project ID from resource: #{resource}")
            return
          end

          project_id.to_s
        end

        # Fetches all registry repositories for a project
        #
        # @param [String] project_id Project ID
        # @return [Array<Hash>] Array of repository objects
        def fetch_registry_repositories(project_id)
          response = get(Runtime::API::Request.new(api_client,
            "/projects/#{project_id}/registry/repositories").url)

          unless success?(response&.code)
            logger.warn("Failed to fetch registry repositories for project #{project_id}: #{response&.code}")
            return []
          end

          repositories = parse_body(response)
          logger.info("Found #{repositories.length} registry repositories for project #{project_id}")
          repositories
        rescue StandardError => e
          logger.error("Error fetching registry repositories for project #{project_id}: #{e.message}")
          []
        end

        # Removes all tags from a specific repository
        #
        # @param [String] project_id Project ID
        # @param [Hash] repository Repository object with :id
        # @return [void]
        def remove_repository_tags(project_id, repository)
          repository_id = repository[:id]
          logger.info("Removing tags from repository #{repository_id}...")

          tags = fetch_repository_tags(project_id, repository_id)
          return if tags.empty?

          tags.each do |tag|
            delete_registry_tag(project_id, repository_id, tag[:name])
          end

          logger.info("Removed #{tags.length} tags from repository #{repository_id}")
        end

        # Fetches all tags for a specific repository
        #
        # @param [String] project_id Project ID
        # @param [Integer] repository_id Repository ID
        # @return [Array<Hash>] Array of tag objects
        def fetch_repository_tags(project_id, repository_id)
          response = get(Runtime::API::Request.new(api_client,
            "/projects/#{project_id}/registry/repositories/#{repository_id}/tags").url)

          unless success?(response&.code)
            logger.warn("Failed to fetch tags for repository #{repository_id}: #{response&.code}")
            return []
          end

          tags = parse_body(response)
          logger.info("Found #{tags.length} tags in repository #{repository_id}")
          tags
        rescue StandardError => e
          logger.error("Error fetching tags for repository #{repository_id}: #{e.message}")
          []
        end

        # Deletes a specific registry tag
        #
        # @param [String] project_id Project ID
        # @param [Integer] repository_id Repository ID
        # @param [String] tag_name Tag name to delete
        # @return [void]
        def delete_registry_tag(project_id, repository_id, tag_name)
          response = delete(Runtime::API::Request.new(api_client,
            "/projects/#{project_id}/registry/repositories/#{repository_id}/tags/#{tag_name}").url)

          if success?(response&.code)
            logger.info("Deleted tag '#{tag_name}' from repository #{repository_id}")
          else
            logger.warn("Failed to delete tag '#{tag_name}' from repository #{repository_id}: #{response&.code}")
          end
        rescue StandardError => e
          logger.error("Error deleting tag '#{tag_name}' from repository #{repository_id}: #{e.message}")
        end

        # Deletes a registry repository
        #
        # @param [String] project_id Project ID
        # @param [Integer] repository_id Repository ID
        # @return [void]
        def delete_registry_repository(project_id, repository_id)
          response = delete(Runtime::API::Request.new(api_client,
            "/projects/#{project_id}/registry/repositories/#{repository_id}").url)

          if success?(response&.code)
            logger.info("Deleted registry repository #{repository_id}")
          else
            logger.warn("Failed to delete registry repository #{repository_id}: #{response&.code}")
          end
        rescue StandardError => e
          logger.error("Error deleting registry repository #{repository_id}: #{e.message}")
        end
      end
    end
  end
end
