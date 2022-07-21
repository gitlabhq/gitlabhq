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
      end
    end
  end
end
