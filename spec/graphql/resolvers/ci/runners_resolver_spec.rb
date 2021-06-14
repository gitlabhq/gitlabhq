# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnersResolver do
  include GraphqlHelpers

  let_it_be(:user) { create_default(:user, :admin) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :repository, :public) }

  let_it_be(:inactive_project_runner) do
    create(:ci_runner, :project, projects: [project], description: 'inactive project runner', token: 'abcdef', active: false, contacted_at: 1.minute.ago, tag_list: %w(project_runner))
  end

  let_it_be(:offline_project_runner) do
    create(:ci_runner, :project, projects: [project], description: 'offline project runner', token: 'defghi', contacted_at: 1.day.ago, tag_list: %w(project_runner active_runner))
  end

  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], token: 'mnopqr', description: 'group runner', contacted_at: 1.second.ago) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, description: 'shared runner', token: 'stuvxz', contacted_at: 2.minutes.ago, tag_list: %w(instance_runner active_runner)) }

  describe '#resolve' do
    subject { resolve(described_class, ctx: { current_user: user }, args: args).items.to_a }

    let(:args) do
      {}
    end

    context 'when the user cannot see runners' do
      let(:user) { create(:user) }

      it 'returns no runners' do
        is_expected.to be_empty
      end
    end

    context 'without sort' do
      it 'returns all the runners' do
        is_expected.to contain_exactly(inactive_project_runner, offline_project_runner, group_runner, instance_runner)
      end
    end

    context 'with a sort argument' do
      context "set to :contacted_asc" do
        let(:args) do
          { sort: :contacted_asc }
        end

        it { is_expected.to eq([offline_project_runner, instance_runner, inactive_project_runner, group_runner]) }
      end

      context "set to :contacted_desc" do
        let(:args) do
          { sort: :contacted_desc }
        end

        it { is_expected.to eq([offline_project_runner, instance_runner, inactive_project_runner, group_runner].reverse) }
      end

      context "set to :created_at_desc" do
        let(:args) do
          { sort: :created_at_desc }
        end

        it { is_expected.to eq([instance_runner, group_runner, offline_project_runner, inactive_project_runner]) }
      end

      context "set to :created_at_asc" do
        let(:args) do
          { sort: :created_at_asc }
        end

        it { is_expected.to eq([instance_runner, group_runner, offline_project_runner, inactive_project_runner].reverse) }
      end
    end

    context 'when type is filtered' do
      let(:args) do
        { type: runner_type.to_s }
      end

      context 'to instance runners' do
        let(:runner_type) { :instance_type }

        it 'returns the instance runner' do
          is_expected.to contain_exactly(instance_runner)
        end
      end

      context 'to group runners' do
        let(:runner_type) { :group_type }

        it 'returns the group runner' do
          is_expected.to contain_exactly(group_runner)
        end
      end

      context 'to project runners' do
        let(:runner_type) { :project_type }

        it 'returns the project runner' do
          is_expected.to contain_exactly(inactive_project_runner, offline_project_runner)
        end
      end
    end

    context 'when status is filtered' do
      let(:args) do
        { status: runner_status.to_s }
      end

      context 'to active runners' do
        let(:runner_status) { :active }

        it 'returns the instance and group runners' do
          is_expected.to contain_exactly(offline_project_runner, group_runner, instance_runner)
        end
      end

      context 'to offline runners' do
        let(:runner_status) { :offline }

        it 'returns the offline project runner' do
          is_expected.to contain_exactly(offline_project_runner)
        end
      end
    end

    context 'when tag list is filtered' do
      let(:args) do
        { tag_list: tag_list }
      end

      context 'with "project_runner" tag' do
        let(:tag_list) { ['project_runner'] }

        it 'returns the project_runner runners' do
          is_expected.to contain_exactly(offline_project_runner, inactive_project_runner)
        end
      end

      context 'with "project_runner" and "active_runner" tags as comma-separated string' do
        let(:tag_list) { ['project_runner,active_runner'] }

        it 'returns the offline_project_runner runner' do
          is_expected.to contain_exactly(offline_project_runner)
        end
      end

      context 'with "active_runner" and "instance_runner" tags as array' do
        let(:tag_list) { %w[instance_runner active_runner] }

        it 'returns the offline_project_runner runner' do
          is_expected.to contain_exactly(instance_runner)
        end
      end
    end

    context 'when text is filtered' do
      let(:args) do
        { search: search_term }
      end

      context 'to "project"' do
        let(:search_term) { 'project' }

        it 'returns both project runners' do
          is_expected.to contain_exactly(inactive_project_runner, offline_project_runner)
        end
      end

      context 'to "group"' do
        let(:search_term) { 'group' }

        it 'returns group runner' do
          is_expected.to contain_exactly(group_runner)
        end
      end

      context 'to "defghi"' do
        let(:search_term) { 'defghi' }

        it 'returns runners containing term in token' do
          is_expected.to contain_exactly(offline_project_runner)
        end
      end
    end
  end
end
