# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', product_group: :import_and_integrate do
    describe 'Gitlab migration', :import, :orchestrated, requires_admin: 'creates a user via API' do
      include_context 'with gitlab project migration'

      # this spec is used as a sanity test for gitlab migration because it can run outside of orchestrated setup
      context 'with import within same instance', :skip_live_env, orchestrated: false, import: false do
        let!(:source_project_with_readme) { true }
        let!(:source_gitlab_address) { Runtime::Scenario.gitlab_address }
        let!(:source_admin_api_client) { admin_api_client }

        # do not use top level group (sandbox) to avoid issues when applying permissions etc. because it will contain
        # a lot subgroups and projects on live envs
        let!(:source_sandbox) { create(:group, api_client: admin_api_client) }

        let!(:source_group) do
          create(:group,
            api_client: admin_api_client,
            sandbox: source_sandbox,
            path: "source-group-for-import-#{SecureRandom.hex(4)}",
            avatar: File.new(Runtime::Path.fixture('designs', 'tanuki.jpg'), 'r'))
        end

        let!(:target_sandbox) { source_sandbox }

        let(:destination_group_path) { "target-group-for-import-#{SecureRandom.hex(4)}" }

        it(
          'successfully imports project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383351',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478101',
            type: :flaky
          }
        ) do
          expect_project_import_finished_successfully

          expect(imported_project).to eq(source_project)
        end
      end

      context 'with uninitialized project' do
        it(
          'successfully imports project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347610',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478099',
            type: :flaky
          }
        ) do
          expect_project_import_finished_successfully

          expect(imported_project).to eq(source_project)
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
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347570',
          quarantine: {
            type: :bug,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422430'
          }
        ) do
          expect_project_import_finished_successfully

          aggregate_failures do
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
          expect_project_import_finished_successfully

          expect(imported_project.wikis).to eq(source_project.wikis)
        end
      end
    end
  end
end
