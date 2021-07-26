# frozen_string_literal: true

require 'octokit'
require 'parallel'

# rubocop:disable Rails/Pluck
module QA
  # Only executes in custom job/pipeline
  RSpec.describe 'Manage', :github, :requires_admin, only: { job: 'large-github-import' } do
    describe 'Project import' do
      let(:api_client) { Runtime::API::Client.as_admin }
      let(:group) do
        Resource::Group.fabricate_via_api! do |resource|
          resource.api_client = api_client
        end
      end

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.hard_delete_on_api_removal = true
        end
      end

      let(:differ) { RSpec::Support::Differ.new(color: true) }
      let(:github_repo) { 'allure-framework/allure-ruby' }

      let(:github_client) do
        Octokit.middleware = Faraday::RackBuilder.new do |builder|
          builder.response(:logger, Runtime::Logger.logger, headers: false, bodies: false)
        end

        Octokit::Client.new(access_token: Runtime::Env.github_access_token, auto_paginate: true)
      end

      let(:gh_branches) { github_client.branches(github_repo).map(&:name) }
      let(:gh_commits) { github_client.commits(github_repo).map(&:sha) }
      let(:gh_repo) { github_client.repository(github_repo) }
      let(:gh_labels) { github_client.labels(github_repo) }
      let(:gh_milestones) { github_client.list_milestones(github_repo, state: 'all') }

      let(:gh_all_issues) do
        github_client.list_issues(github_repo, state: 'all')
      end

      let(:gh_prs) do
        gh_all_issues.select(&:pull_request).each_with_object({}) do |pr, hash|
          hash[pr.title] = {
            body: pr.body || '',
            comments: [*gh_pr_comments[pr.html_url], *gh_issue_comments[pr.html_url]].compact.sort
          }
        end
      end

      let(:gh_issues) do
        gh_all_issues.reject(&:pull_request).each_with_object({}) do |issue, hash|
          hash[issue.title] = {
            body: issue.body || '',
            comments: gh_issue_comments[issue.html_url]
          }
        end
      end

      let(:gh_issue_comments) do
        github_client.issues_comments(github_repo).each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[c.html_url.gsub(/\#\S+/, "")] << c.body # use base html url as key
        end
      end

      let(:gh_pr_comments) do
        github_client.pull_requests_comments(github_repo).each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[c.html_url.gsub(/\#\S+/, "")] << c.body # use base html url as key
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
          project.add_name_uuid = false
          project.name = 'imported-project'
          project.group = group
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = github_repo
          project.api_client = api_client
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      it 'imports large Github repo via api' do
        imported_project # import the project
        fetch_github_objects # fetch all objects right after import has started

        expect { imported_project.reload!.import_status }.to eventually_eq('finished').within(
          duration: 3600,
          interval: 30
        )

        aggregate_failures do
          verify_repository_import
          verify_merge_requests_import
          verify_issues_import
          verify_labels_import
          verify_milestones_import
        end
      end

      # Persist all objects from repository being imported
      #
      # @return [void]
      def fetch_github_objects
        Runtime::Logger.debug("Fetching objects for github repo: '#{github_repo}'")

        gh_repo
        gh_branches
        gh_commits
        gh_prs
        gh_issues
        gh_labels
        gh_milestones
      end

      # Verify repository imported correctly
      #
      # @return [void]
      def verify_repository_import
        branches = imported_project.repository_branches(auto_paginate: true).map { |b| b[:name] }
        commits = imported_project.commits(auto_paginate: true).map { |c| c[:id] }

        expect(imported_project.description).to eq(gh_repo.description)
        # check via include, importer creates more branches
        # https://gitlab.com/gitlab-org/gitlab/-/issues/332711
        expect(branches).to include(*gh_branches)
        expect(commits).to match_array(gh_commits)
      end

      # Verify imported merge requests and mr issues
      #
      # @return [void]
      def verify_merge_requests_import
        verify_mrs_or_issues('mrs')
      end

      # Verify imported issues and issue comments
      #
      # @return [void]
      def verify_issues_import
        verify_mrs_or_issues('issues')
      end

      # Verify imported labels
      #
      # @return [void]
      def verify_labels_import
        labels = imported_project.labels(auto_paginate: true).map { |label| label.slice(:name, :color) }
        actual_labels = gh_labels.map { |label| { name: label.name, color: "##{label.color}" } }

        expect(labels.length).to eq(actual_labels.length)
        expect(labels).to match_array(actual_labels)
      end

      # Verify milestones import
      #
      # @return [void]
      def verify_milestones_import
        milestones = imported_project.milestones(auto_paginate: true).map { |ms| ms.slice(:title, :description) }
        actual_milestones = gh_milestones.map { |ms| { title: ms.title, description: ms.description } }

        expect(milestones.length).to eq(actual_milestones.length)
        expect(milestones).to match_array(actual_milestones)
      end

      private

      # Verify imported mrs or issues
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @return [void]
      def verify_mrs_or_issues(type)
        msg = ->(title) { "expected #{type} with title '#{title}' to have" }
        expected = type == 'mrs' ? mrs : gl_issues
        actual = type == 'mrs' ? gh_prs : gh_issues

        expect(expected.keys).to match_array(actual.keys)
        actual.each do |title, actual_item|
          expected_item = expected[title]

          expect(expected_item).to be_truthy, "#{msg.call(title)} been imported"
          next unless expected_item

          expect(expected_item[:body]).to(
            include(actual_item[:body]),
            "#{msg.call(title)} same description. #{diff(expected_item[:body], actual_item[:body])}"
          )
          expect(expected_item[:comments].length).to(
            eq(actual_item[:comments].length),
            "#{msg.call(title)} same amount of comments"
          )
          expect(expected_item[:comments]).to match_array(actual_item[:comments])
        end
      end

      # Imported project merge requests
      #
      # @return [Hash]
      def mrs
        @mrs ||= begin
          imported_mrs = imported_project.merge_requests(auto_paginate: true)
          # fetch comments in parallel since we need to do it for each mr separately
          mrs_hashes = Parallel.map(imported_mrs, in_processes: 5) do |mr|
            resource = Resource::MergeRequest.init do |resource|
              resource.project = imported_project
              resource.iid = mr[:iid]
              resource.api_client = api_client
            end

            {
              title: mr[:title],
              body: mr[:description],
              comments: resource.comments(auto_paginate: true)
                # remove system notes
                .reject { |c| c[:system] || c[:body].match?(/^(\*\*Review:\*\*)|(\*Merged by:).*/) }
                .map { |c| sanitize(c[:body]) }
            }
          end

          mrs_hashes.each_with_object({}) do |mr, hash|
            hash[mr[:title]] = {
              body: mr[:body],
              comments: mr[:comments]
            }
          end
        end
      end

      # Imported project issues
      #
      # @return [Hash]
      def gl_issues
        @gl_issues ||= begin
          imported_issues = imported_project.issues(auto_paginate: true)
          # fetch comments in parallel since we need to do it for each mr separately
          issue_hashes = Parallel.map(imported_issues, in_processes: 5) do |issue|
            resource = Resource::Issue.init do |issue_resource|
              issue_resource.project = imported_project
              issue_resource.iid = issue[:iid]
              issue_resource.api_client = api_client
            end

            {
              title: issue[:title],
              body: issue[:description],
              comments: resource.comments(auto_paginate: true).map { |c| sanitize(c[:body]) }
            }
          end

          issue_hashes.each_with_object({}) do |issue, hash|
            hash[issue[:title]] = {
              body: issue[:body],
              comments: issue[:comments]
            }
          end
        end
      end

      # Remove added prefixes by importer
      #
      # @param [String] body
      # @return [String]
      def sanitize(body)
        body.gsub(/\*Created by: \S+\*\n\n/, "")
      end

      # Diff of 2 objects
      #
      # @param [Object] actual
      # @param [Object] expected
      # @return [String]
      def diff(actual, expected)
        "diff:\n#{differ.diff(actual, expected)}"
      end
    end
  end
end
# rubocop:enable Rails/Pluck
