# frozen_string_literal: true

require 'yaml'

# This script generates testdata for Performance Testing.
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# This job creates a urls.txt which contains a hash of all the URLs needed for Performance Testing
# Run `rake generate_perf_testdata`

module QA
  module Tools
    class GeneratePerfTestdata
      include Support::API

      def initialize
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @group_name = ENV['GROUP_NAME'] || "gitlab-qa-perf-sandbox-#{SecureRandom.hex(8)}"
        @project_name = ENV['PROJECT_NAME'] || "my-test-project-#{SecureRandom.hex(8)}"
        @visibility = "public"
        @urls = { host: ENV['GITLAB_ADDRESS'] }
      end

      def all
        $stdout.puts 'Running...'
        group_id = create_group
        create_project(group_id)

        create_many_branches
        create_many_new_files
        create_mr_with_many_commits
        create_many_issues

        methods_arr = [
          method(:create_many_labels),
          method(:create_many_todos),
          method(:create_many_merge_requests),
          method(:create_an_issue_with_many_discussions),
          method(:create_an_mr_with_large_files_and_many_mr_discussions)
        ]

        threads_arr = []

        methods_arr.each do |m|
          threads_arr << Thread.new { m.call }
        end

        threads_arr.each(&:join)
        $stdout.puts "\nURLs: #{@urls}"
        File.open("urls.yml", "w") { |file| file.puts @urls.stringify_keys.to_yaml }
        $stdout.puts "\nDone"
      end

      def create_group
        group_search_response = create_a_group_api_req(@group_name, @visibility)
        group = JSON.parse(group_search_response.body)
        @urls[:group_page] = group["web_url"]
        $stdout.puts "Created a group: #{@urls[:group_page]}"
        group["id"]
      end

      def create_project(group_id)
        create_project_response = create_a_project_api_req(@project_name, group_id, @visibility)
        @urls[:project_page] = JSON.parse(create_project_response.body)["web_url"]
        $stdout.puts "Created a project: #{@urls[:project_page]}"
      end

      def create_many_issues
        30.times do |i|
          create_an_issue_api_req("#{@group_name}%2F#{@project_name}", "issue#{i}", "desc#{i}")
        end
        @urls[:issues_list_page] = @urls[:project_page] + "/issues"
        $stdout.puts "Created many issues: #{@urls[:issues_list_page]}"
      end

      def create_many_todos
        30.times do |i|
          create_a_todo_api_req("#{@group_name}%2F#{@project_name}", (i + 1).to_s)
        end
        @urls[:todos_page] = ENV['GITLAB_ADDRESS'] + "/dashboard/todos"
        $stdout.puts "Created many todos: #{@urls[:todos_page]}"
      end

      def create_many_labels
        30.times do |i|
          create_a_label_api_req("#{@group_name}%2F#{@project_name}", "label#{i}", Faker::Color.hex_color.to_s)
        end
        @urls[:labels_page] = @urls[:project_page] + "/labels"
        $stdout.puts "Created many labels: #{@urls[:labels_page]}"
      end

      def create_many_merge_requests
        30.times do |i|
          create_a_merge_request_api_req("#{@group_name}%2F#{@project_name}", "branch#{i}", Runtime::Env.default_branch, "MR#{i}")
        end
        @urls[:mr_list_page] = @urls[:project_page] + "/merge_requests"
        $stdout.puts "Created many MRs: #{@urls[:mr_list_page]}"
      end

      def create_many_new_files
        create_a_new_file_api_req("hello.txt", Runtime::Env.default_branch, "#{@group_name}%2F#{@project_name}", "hello", "my new content")
        30.times do |i|
          create_a_new_file_api_req("hello#{i}.txt", Runtime::Env.default_branch, "#{@group_name}%2F#{@project_name}", "hello", "my new content")
          create_a_new_file_api_req("hello#{i}.txt", "branch#{i}", "#{@group_name}%2F#{@project_name}", "hello", "my new content")
        end

        @urls[:files_page] = @urls[:project_page] + "/tree/#{Runtime::Env.default_branch}"
        $stdout.puts "Added many new files: #{@urls[:files_page]}"
      end

      def create_many_branches
        30.times do |i|
          create_a_branch_api_req("branch#{i}", "#{@group_name}%2F#{@project_name}")
        end
        @urls[:branches_page] = @urls[:project_page] + "/-/branches"
        $stdout.puts "Created many branches: #{@urls[:branches_page]}"
      end

      def create_an_issue_with_many_discussions
        issue_id = 1
        500.times do
          create_a_discussion_on_issue_api_req("#{@group_name}%2F#{@project_name}", issue_id, "Let us discuss")
        end

        labels_list = (0..15).map { |i| "label#{i}" }.join(',')
        # Add description and labels
        update_an_issue_api_req("#{@group_name}%2F#{@project_name}", issue_id, Faker::Lorem.sentences(500).join(" ").to_s, labels_list)
        @urls[:large_issue] = @urls[:project_page] + "/issues/#{issue_id}"
        $stdout.puts "Created an issue with many discussions: #{@urls[:large_issue]}"
      end

      def create_an_mr_with_large_files_and_many_mr_discussions
        content_arr = []
        16.times do |i|
          faker_line_arr = Faker::Lorem.sentences(1500)
          content = faker_line_arr.join("\n\r")
          create_a_new_file_api_req("hello#{i + 100}.txt", Runtime::Env.default_branch, "#{@group_name}%2F#{@project_name}", "Add hello#{i + 100}.txt", content)
          content_arr[i] = faker_line_arr
        end

        create_a_branch_api_req("performance", "#{@group_name}%2F#{@project_name}")

        16.times do |i|
          missed_line_array = content_arr[i].each_slice(2).map(&:first)
          content = missed_line_array.join("\n\rIm new!:D \n\r ")

          update_file_api_req("hello#{i + 100}.txt", "performance", "#{@group_name}%2F#{@project_name}", "Update hello#{i + 100}.txt", content)
        end

        create_mr_response = create_a_merge_request_api_req("#{@group_name}%2F#{@project_name}", "performance", Runtime::Env.default_branch, "Large_MR")

        iid = JSON.parse(create_mr_response.body)["iid"]
        diff_refs = JSON.parse(create_mr_response.body)["diff_refs"]

        # Add discussions to diff tab and resolve a few!
        should_resolve = false
        16.times do |i|
          1.upto(9) do |j|
            create_diff_note(iid, i, j, diff_refs["head_sha"], diff_refs["start_sha"], diff_refs["base_sha"], "new_line")
            create_diff_note_response = create_diff_note(iid, i, j, diff_refs["head_sha"], diff_refs["start_sha"], diff_refs["base_sha"], "old_line")

            if should_resolve
              discussion_id = JSON.parse(create_diff_note_response.body)["id"]

              update_a_discussion_on_issue_api_req("#{@group_name}%2F#{@project_name}", iid, discussion_id, "true")
            end

            should_resolve ^= true
          end
        end

        # Add discussions to main tab
        100.times do
          create_a_discussion_on_mr_api_req("#{@group_name}%2F#{@project_name}", iid, "Let us discuss")
        end
        @urls[:large_mr] = JSON.parse(create_mr_response.body)["web_url"]
        $stdout.puts "Created an MR with many discussions and many very large Files: #{@urls[:large_mr]}"
      end

      def create_diff_note(iid, file_count, line_count, head_sha, start_sha, base_sha, line_type)
        url = Runtime::API::Request.new(@api_client,
          "/projects/#{@group_name}%2F#{@project_name}/merge_requests/#{iid}/discussions").url
        post url, <<~PARAMS
          body="Let us discuss"&
          position[position_type]=text&
          position[new_path]=hello#{file_count}.txt&
          position[old_path]=hello#{file_count}.txt&
          position[#{line_type}]=#{line_count * 100}&
          position[head_sha]=#{head_sha}&
          position[start_sha]=#{start_sha}&
          position[base_sha]=#{base_sha}
        PARAMS
      end

      def create_mr_with_many_commits
        project_path = "#{@group_name}%2F#{@project_name}"
        branch_name = "branch_with_many_commits-#{SecureRandom.hex(8)}"
        file_name = "file_for_many_commits.txt"

        create_a_branch_api_req(branch_name, project_path)
        create_a_new_file_api_req(file_name, branch_name, project_path, "Initial commit for new file", "Initial file content")
        create_mr_response = create_a_merge_request_api_req(project_path, branch_name, Runtime::Env.default_branch, "MR with many commits-#{SecureRandom.hex(8)}")
        @urls[:mr_with_many_commits] = JSON.parse(create_mr_response.body)["web_url"]
        100.times do |i|
          update_file_api_req(file_name, branch_name, project_path, Faker::Lorem.sentences(5).join(" "), Faker::Lorem.sentences(500).join("\n"))
        end
        $stdout.puts "Using branch: #{branch_name}, created an MR with many commits: #{@urls[:mr_with_many_commits]}"
      end

      private

      # API Requests

      def create_a_discussion_on_issue_api_req(project_path_or_id, issue_id, body)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/issues/#{issue_id}/discussions").url, "body=\"#{body}\""
        end
      end

      def update_a_discussion_on_issue_api_req(project_path_or_id, mr_iid, discussion_id, resolved_status)
        call_api(expected_response_code: 200) do
          put Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/merge_requests/#{mr_iid}/discussions/#{discussion_id}").url, "resolved=#{resolved_status}"
        end
      end

      def create_a_discussion_on_mr_api_req(project_path_or_id, mr_iid, body)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/merge_requests/#{mr_iid}/discussions").url, "body=\"#{body}\""
        end
      end

      def create_a_label_api_req(project_path_or_id, name, color)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/labels").url, "name=#{name}&color=#{color}"
        end
      end

      def create_a_todo_api_req(project_path_or_id, issue_id)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/issues/#{issue_id}/todo").url, nil
        end
      end

      def create_an_issue_api_req(project_path_or_id, title, description)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/issues").url, "title=#{title}&description=#{description}"
        end
      end

      def update_an_issue_api_req(project_path_or_id, issue_id, description, labels_list)
        call_api(expected_response_code: 200) do
          put Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/issues/#{issue_id}").url, "description=#{description}&labels=#{labels_list}"
        end
      end

      def create_a_project_api_req(project_name, group_id, visibility)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects").url, "name=#{project_name}&namespace_id=#{group_id}&visibility=#{visibility}"
        end
      end

      def create_a_group_api_req(group_name, visibility)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/groups").url, "name=#{group_name}&path=#{group_name}&visibility=#{visibility}"
        end
      end

      def create_a_branch_api_req(branch_name, project_path_or_id)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/repository/branches").url, "branch=#{branch_name}&ref=#{Runtime::Env.default_branch}"
        end
      end

      def create_a_new_file_api_req(file_path, branch_name, project_path_or_id, commit_message, content)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/repository/files/#{file_path}").url, "branch=#{branch_name}&commit_message=\"#{commit_message}\"&content=\"#{content}\""
        end
      end

      def create_a_merge_request_api_req(project_path_or_id, source_branch, target_branch, mr_title)
        call_api(expected_response_code: 201) do
          post Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/merge_requests").url, "source_branch=#{source_branch}&target_branch=#{target_branch}&title=#{mr_title}"
        end
      end

      def update_file_api_req(file_path, branch_name, project_path_or_id, commit_message, content)
        call_api(expected_response_code: 200) do
          put Runtime::API::Request.new(@api_client, "/projects/#{project_path_or_id}/repository/files/#{file_path}").url, "branch=#{branch_name}&commit_message=\"#{commit_message}\"&content=\"#{content}\""
        end
      end

      def call_api(expected_response_code: 200)
        response = yield
        raise "API call failed with response code: #{response.code} and body: #{response.body}" unless response.code == expected_response_code

        response
      end
    end
  end
end
