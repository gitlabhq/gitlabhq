# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesHelper, feature_category: :team_planning do
  include ProjectForksHelper

  let_it_be(:current_user) { build(:user) }
  let_it_be(:project) { build(:project, :public) }
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- forked projects require persistence
  let_it_be(:source_project) { create(:project, :public) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate
  let_it_be(:forked_project) { fork_project(source_project, current_user, repository: true) }

  describe '#create_mr_tracking_data' do
    using RSpec::Parameterized::TableSyntax

    where(:can_create_mr, :can_create_confidential_mr, :tracking_data) do
      true  | true  | { event_tracking: 'click_create_confidential_mr_issues_list' }
      true  | false | { event_tracking: 'click_create_mr_issues_list' }
      false | false | {}
    end

    with_them do
      it do
        expect(create_mr_tracking_data(can_create_mr, can_create_confidential_mr)).to eq(tracking_data)
      end
    end
  end

  describe '#default_target' do
    context 'when a project has no forks' do
      it 'returns the same project' do
        expect(default_target(project)).to be project
      end
    end

    context 'when a project has forks' do
      it 'returns the source project' do
        expect(default_target(forked_project)).to eq source_project
      end
    end
  end

  describe '#target_projects' do
    it 'returns all the forks and the source project' do
      expect(target_projects(forked_project)).to eq [source_project, forked_project]
    end
  end
end
