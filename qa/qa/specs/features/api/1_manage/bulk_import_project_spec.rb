# frozen_string_literal: true

module QA
  # run only base UI validation on staging because test requires top level group creation which is problematic
  # on staging environment
  RSpec.describe 'Manage', :requires_admin, except: { subdomain: :staging } do
    describe 'Gitlab migration', quarantine: {
      only: { job: 'praefect-parallel' },
      type: :investigating,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/348999'
    } do
      let(:source_project_with_readme) { false }
      let(:import_wait_duration) { { max_duration: 300, sleep_interval: 2 } }
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:api_client) { Runtime::API::Client.new(user: user) }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:source_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.api_client = api_client
          project.group = source_group
          project.initialize_with_readme = source_project_with_readme
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group_path = source_group.path
        end
      end

      let(:imported_projects) { imported_group.reload!.projects }
      let(:imported_project) { imported_projects.first }

      let(:import_failures) do
        imported_group.import_details.sum([]) { |details| details[:failures] }
      end

      def expect_import_finished
        imported_group # trigger import

        expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
        expect(imported_projects.count).to eq(1), 'Expected to have 1 imported project'
      end

      before do
        Runtime::Feature.enable(:bulk_import_projects)

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        source_project # fabricate source group and project
      end

      after do |example|
        # Checking for failures in the test currently makes test very flaky
        # Just log in case of failure until cause of network errors is found
        Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?

        user.remove_via_api!
      ensure
        Runtime::Feature.disable(:bulk_import_projects)
      end

      context 'with project' do
        it(
          'successfully imports project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347610'
        ) do
          expect_import_finished

          expect(imported_projects.first).to eq(source_project)
        end
      end

      context 'with project issues' do
        let!(:source_issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = api_client
            issue.project = source_project
            issue.labels = %w[label_one label_two]
          end
        end

        let!(:source_comment) { source_issue.add_comment(body: 'This is a test comment!') }

        let(:imported_issues) { imported_projects.first.issues }

        let(:imported_issue) do
          issue = imported_issues.first
          Resource::Issue.init do |resource|
            resource.api_client = api_client
            resource.project = imported_projects.first
            resource.iid = issue[:iid]
          end
        end

        let(:imported_comments) { imported_issue.comments }

        it(
          'successfully imports issue',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347608'
        ) do
          expect_import_finished

          aggregate_failures do
            expect(imported_issues.count).to eq(1)
            expect(imported_issue).to eq(source_issue.reload!)

            expect(imported_comments.count).to eq(1)
            expect(imported_comments.first[:body]).to include(source_comment[:body])
          end
        end
      end

      context 'with repository' do
        let(:source_project_with_readme) { true }
        let(:source_commits) { source_project.commits.map { |c| c.except(:web_url) } }
        let(:source_tags) do
          source_project.repository_tags.tap do |tags|
            tags.each { |t| t[:commit].delete(:web_url) }
          end
        end

        let(:source_branches) do
          source_project.repository_branches.tap do |branches|
            branches.each do |b|
              b.delete(:web_url)
              b[:commit].delete(:web_url)
            end
          end
        end

        let(:imported_commits) { imported_project.commits.map { |c| c.except(:web_url) } }
        let(:imported_tags) do
          imported_project.repository_tags.tap do |tags|
            tags.each { |t| t[:commit].delete(:web_url) }
          end
        end

        let(:imported_branches) do
          imported_project.repository_branches.tap do |branches|
            branches.each do |b|
              b.delete(:web_url)
              b[:commit].delete(:web_url)
            end
          end
        end

        before do
          source_project.create_repository_branch('test-branch')
          source_project.create_repository_tag('v0.0.1')
        end

        it(
          'successfully imports repository',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347570'
        ) do
          aggregate_failures do
            expect_import_finished

            expect(imported_commits).to match_array(source_commits)
            expect(imported_tags).to match_array(source_tags)
            expect(imported_branches).to match_array(source_branches)
          end
        end
      end

      context 'with wiki' do
        before do
          source_project.create_wiki_page(title: 'Import test project wiki', content: 'Wiki content')
        end

        it(
          'successfully imports project wiki',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347567'
        ) do
          expect_import_finished

          expect(imported_projects.first.wikis).to eq(source_project.wikis)
        end
      end

      context 'with merge request' do
        let!(:source_project_with_readme) { true }

        let!(:other_user) do
          Resource::User
            .fabricate_via_api! { |usr| usr.api_client = admin_api_client }
            .tap do |usr|
              usr.set_public_email
              source_project.add_member(usr, Resource::Members::AccessLevel::MAINTAINER)
            end
        end

        let!(:source_mr) do
          Resource::MergeRequest.fabricate_via_api! do |mr|
            mr.project = source_project
            mr.api_client = Runtime::API::Client.new(user: other_user)
          end
        end

        let!(:source_comment) { source_mr.add_comment('This is a test comment!') }

        let(:imported_mrs) { imported_project.merge_requests }
        let(:imported_mr_comments) { imported_mr.comments }

        let(:imported_mr) do
          Resource::MergeRequest.init do |mr|
            mr.project = imported_project
            mr.iid = imported_mrs.first[:iid]
            mr.api_client = api_client
          end
        end

        after do
          other_user.remove_via_api!
        end

        it(
          'successfully imports merge request',
          tesecase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348478'
        ) do
          expect_import_finished

          aggregate_failures do
            expect(imported_mrs.count).to eq(1)
            # TODO: remove custom comparison after member migration is implemented
            # https://gitlab.com/gitlab-org/gitlab/-/issues/341886
            expect(imported_mr.comparable.except(:author)).to eq(source_mr.reload!.comparable.except(:author))

            expect(imported_mr_comments.count).to eq(1)
            expect(imported_mr_comments.first[:body]).to include(source_comment[:body])
            # Comment will have mention of original user since members are not migrated yet
            expect(imported_mr_comments.first[:body]).to include(other_user.name)
          end
        end
      end
    end
  end
end
