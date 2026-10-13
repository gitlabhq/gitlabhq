# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::BranchRulesHelper, feature_category: :source_code_management do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { build_stubbed(:project) }

  describe '#branch_rules_data' do
    subject(:data) { helper.branch_rules_data(project) }

    it 'returns branch rules data' do
      expect(data).to include({
        project_path: project.full_path,
        protected_branches_path: project_settings_repository_path(project, anchor: 'js-protected-branches-settings'),
        branch_rules_path: project_settings_repository_path(project, anchor: 'branch-rules'),
        branches_path: project_branches_path(project),
        show_status_checks: 'false',
        show_approvers: 'false',
        show_code_owners: 'false',
        can_admin_protected_branches: 'false',
        can_read_protected_branches: 'false'
      })
    end

    context 'when user can read protected branches' do
      before do
        allow(helper).to receive(:can?).and_call_original
        allow(helper).to receive(:can?).with(anything, :read_protected_branch, project).and_return(true)
      end

      it { is_expected.to include(can_read_protected_branches: 'true') }
    end
  end
end
