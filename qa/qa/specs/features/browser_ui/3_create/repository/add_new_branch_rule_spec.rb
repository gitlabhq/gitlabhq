# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Branch Rules Overview', product_group: :source_code do
      let(:branch_name) { 'new-branch' }
      let(:allowed_to_push_role) { Resource::ProtectedBranch::Roles::NO_ONE }
      let(:allowed_to_merge_role) { Resource::ProtectedBranch::Roles::MAINTAINERS }
      let(:project) { create(:project, :with_readme, name: 'branch-rule-project') }

      before do
        Flow::Login.sign_in

        create(:commit,
          project: project, branch: branch_name,
          start_branch: project.default_branch,
          commit_message: 'First commit', actions: [
            { action: 'create', file_path: 'new_file.rb', content: '# new content' }
          ])
      end

      it 'adds a new branch rule',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/397587' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform(&:expand_protected_branches)

        Page::Project::Settings::ProtectedBranches.perform do |settings|
          settings.select_branch(branch_name)
          settings.select_allowed_to_push(roles: allowed_to_push_role)
          settings.select_allowed_to_merge(roles: allowed_to_merge_role)
          settings.protect_branch
        end

        Page::Project::Settings::Repository.perform(&:expand_branch_rules)

        Page::Project::Settings::BranchRules.perform do |rules|
          expect(rules).to have_content(branch_name)
          rules.navigate_to_branch_rules_details(branch_name)
        end

        Page::Project::Settings::BranchRulesDetails.perform do |details|
          aggregate_failures 'branch rules details' do
            expect(details).to have_allowed_to_push(allowed_to_push_role[:description])
            expect(details).to have_allowed_to_merge(allowed_to_merge_role[:description])
          end
        end
      end
    end
  end
end
