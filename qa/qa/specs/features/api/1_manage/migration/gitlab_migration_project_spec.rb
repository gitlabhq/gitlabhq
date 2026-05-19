# frozen_string_literal: true

module QA
  RSpec.describe 'Manage',
    feature_category: :importers do
    describe 'Gitlab migration', :import, :orchestrated, requires_admin: 'creates a user via API' do
      include_context 'with gitlab project migration'

      context 'with uninitialized project' do
        it(
          'successfully imports project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347610'
        ) do
          expect_project_import_finished_successfully

          aggregate_failures do
            expect(imported_project.name).to eq(source_project.name)
            expect(imported_project.description).to eq(source_project.description)
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

        # Extract only git-data fields from branches for comparison.
        # Excludes project-level settings (protected, can_push, developers_can_merge,
        # developers_can_push) and instance-specific fields (web_url) that legitimately
        # differ between source and imported projects.
        let(:source_branches) { comparable_branches(source_project.repository_branches) }

        let(:imported_commits) { imported_project.commits.map { |c| c.except(:web_url) } }
        let(:imported_tags) do
          imported_project.repository_tags.tap do |tags|
            tags.each { |t| t[:commit].delete(:web_url) }
          end
        end

        let(:imported_branches) { comparable_branches(imported_project.repository_branches) }

        def comparable_branches(branches)
          branches.map do |b|
            {
              name: b[:name],
              default: b[:default],
              merged: b[:merged],
              commit: b[:commit].except(:web_url)
            }
          end
        end

        before do
          source_project.create_repository_branch('test-branch')
          source_project.create_repository_tag('v0.0.1')
          source_project.change_default_branch('main')
        end

        it(
          'successfully imports repository',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347570'
        ) do
          expect_project_import_finished_successfully

          aggregate_failures do
            expect(imported_project.default_branch).to eq('main')
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

          # Exclude wiki_page_meta_id from comparison as it is a database primary key
          # that will always differ between source and imported projects.
          comparable_fields = ->(wikis) { wikis.map { |w| w.except(:wiki_page_meta_id) } }

          expect(comparable_fields.call(imported_project.wikis)).to eq(comparable_fields.call(source_project.wikis))
        end
      end
    end
  end
end
