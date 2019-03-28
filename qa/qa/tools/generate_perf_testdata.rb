# frozen_string_literal: true

require 'securerandom'
require 'faker'
require 'yaml'
require_relative '../../qa'
# This script generates testdata for Performance Testing.
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# This job creates a urls.txt which contains a hash of all the URLs needed for Performance Testing
# Run `rake generate_perf_testdata`

module QA
  module Tools
    class GeneratePerfTestdata
      include Support::Api

      def initialize
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @group_name = "gitlab-qa-perf-sandbox-#{SecureRandom.hex(8)}"
        @project_name = "my-test-project-#{SecureRandom.hex(8)}"
        @visibility = "public"
        @urls = { host: ENV['GITLAB_ADDRESS'] }
      end

      def run
        STDOUT.puts 'Running...'
        group_id = create_group
        create_project(group_id)
        create_branch
        add_new_file
        methods_arr = [
          method(:create_issues),
          method(:create_todos),
          method(:create_merge_requests),
          method(:create_issue_with_500_discussions),
          method(:create_mr_with_large_files)
        ]
        threads_arr = []

        methods_arr.each do |m|
          threads_arr << Thread.new { m.call }
        end

        threads_arr.each(&:join)
        STDOUT.puts "\nURLs: #{@urls}"
        File.open("urls.yml", "w") { |file| file.puts @urls.stringify_keys.to_yaml }
        STDOUT.puts "\nDone"
      end

      private

      def create_group
        group_search_response = post Runtime::API::Request.new(@api_client, "/groups").url, "name=#{@group_name}&path=#{@group_name}&visibility=#{@visibility}"
        group = JSON.parse(group_search_response.body)
        @urls[:group_page] = group["web_url"]
        group["id"]
      end

      def create_project(group_id)
        create_project_response = post Runtime::API::Request.new(@api_client, "/projects").url, "name=#{@project_name}&namespace_id=#{group_id}&visibility=#{@visibility}"
        @urls[:project_page] = JSON.parse(create_project_response.body)["web_url"]
      end

      def create_issues
        30.times do |i|
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/issues").url, "title=issue#{i}&description=desc#{i}"
        end
        @urls[:issues_list_page] = @urls[:project_page] + "/issues"
        STDOUT.puts "Created Issues"
      end

      def create_todos
        30.times do |i|
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/issues/#{i + 1}/todo").url, nil
        end
        @urls[:todos_page] = ENV['GITLAB_ADDRESS'] + "/dashboard/todos"
        STDOUT.puts "Created todos"
      end

      def create_merge_requests
        30.times do |i|
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/merge_requests").url, "source_branch=branch#{i}&target_branch=master&title=MR#{i}"
        end
        @urls[:mr_list_page] = @urls[:project_page] + "/merge_requests"
        STDOUT.puts "Created MRs"
      end

      def add_new_file
        post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/files/hello.txt").url, "branch=master&commit_message=\"hello\"&content=\"my new content\""
        30.times do |i|
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/files/hello#{i}.txt").url, "branch=branch#{i}&commit_message=\"hello\"&content=\"my new content\""
        end
        STDOUT.puts "Added Files"
      end

      def create_branch
        30.times do |i|
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/branches").url, "branch=branch#{i}&ref=master"
        end
        STDOUT.puts "Created branches"
      end

      def create_issue_with_500_discussions
        issue_id = 1
        500.times do
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/issues/#{issue_id}/discussions").url, "body=\"Let us discuss\""
        end
        @urls[:large_issue] = @urls[:project_page] + "/issues/#{issue_id}"
        STDOUT.puts "Created Issue with 500 Discussions"
      end

      def create_mr_with_large_files
        content_arr = []
        20.times do |i|
          faker_line_arr = Faker::Lorem.sentences(1500)
          content = faker_line_arr.join("\n\r")
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/files/hello#{i}.txt").url, "branch=master&commit_message=\"Add hello#{i}.txt\"&content=#{content}"
          content_arr[i] = faker_line_arr
        end

        post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/branches").url, "branch=performance&ref=master"

        20.times do |i|
          missed_line_array = content_arr[i].each_slice(2).map(&:first)
          content = missed_line_array.join("\n\rIm new!:D \n\r ")
          put Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/repository/files/hello#{i}.txt").url, "branch=performance&commit_message=\"Update hello#{i}.txt\"&content=#{content}"
        end

        create_mr_response = post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/merge_requests").url, "source_branch=performance&target_branch=master&title=Large_MR"

        iid = JSON.parse(create_mr_response.body)["iid"]
        500.times do
          post Runtime::API::Request.new(@api_client, "/projects/#{@group_name}%2F#{@project_name}/merge_requests/#{iid}/discussions").url, "body=\"Let us discuss\""
        end
        @urls[:large_mr] = JSON.parse(create_mr_response.body)["web_url"]
        STDOUT.puts "Created MR with 500 Discussions and 20 Very Large Files"
      end
    end
  end
end
