# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersFinder, '#execute', feature_category: :fleet_visibility do
  let(:params) { {} }

  subject(:execute) do
    described_class.new(current_user: current_user, params: params).execute
  end

  context 'admin' do
    let_it_be(:admin) { create(:user, :admin) }

    let(:current_user) { admin }

    shared_examples 'executes as admin' do
      context 'with 2 runners' do
        let_it_be(:runner1) { create(:ci_runner) }
        let_it_be(:runner2) { create(:ci_runner, :paused) }

        context 'with empty params' do
          it 'returns all runners' do
            expect(Ci::Runner).to receive(:with_tags).and_call_original
            expect(execute).to match_array [runner1, runner2]
          end
        end

        context 'with nil group' do
          let(:params) { { group: nil } }

          it 'returns all runners' do
            expect(Ci::Runner).to receive(:with_tags).and_call_original
            expect(execute).to match_array [runner1, runner2]
          end
        end

        context 'with preload param set to :tag_name true' do
          let(:params) { { preload: { tag_name: true } } }

          it 'requests tags' do
            expect(Ci::Runner).to receive(:with_tags).and_call_original
            expect(execute).to match_array [runner1, runner2]
          end
        end

        context 'with preload param set to :tag_name false' do
          let(:params) { { preload: { tag_name: false } } }

          it 'does not request tags' do
            expect(Ci::Runner).not_to receive(:with_tags)
            expect(execute).to match_array [runner1, runner2]
          end
        end
      end

      context 'filtering' do
        context 'by search term' do
          let(:params) { { search: 'term' } }

          it 'calls Ci::Runner.search' do
            expect(Ci::Runner).to receive(:search).with('term').and_call_original

            execute
          end
        end

        context 'by upgrade status' do
          let(:upgrade_status) {}
          let(:params) { { upgrade_status: upgrade_status } }

          let_it_be(:runner1) { create(:ci_runner) }
          let_it_be(:runner2) { create(:ci_runner) }
          let_it_be(:runner_manager_1) { create(:ci_runner_machine, runner: runner1, version: 'a') }
          let_it_be(:runner_manager_2) { create(:ci_runner_machine, runner: runner2, version: 'b') }
          let_it_be(:runner_manager_3) { create(:ci_runner_machine, runner: runner2, version: 'c') }
          let_it_be(:runner_version_recommended) do
            create(:ci_runner_version, version: 'a', status: :recommended)
          end

          let_it_be(:runner_version_unavailable) do
            create(:ci_runner_version, version: 'b', status: :unavailable)
          end

          let_it_be(:runner_version_available) do
            create(:ci_runner_version, version: 'c', status: :available)
          end

          Ci::RunnerVersion.statuses.keys.map(&:to_sym).each do |status|
            context "set to :#{status}" do
              let(:upgrade_status) { status }

              it "calls with_upgrade_status scope with corresponding :#{status} status" do
                if [:available, :unavailable, :recommended].include?(status)
                  expected_result = Ci::Runner.with_upgrade_status(status)
                end

                expect(Ci::Runner).to receive(:with_upgrade_status).with(status).and_call_original

                execute

                expect(execute).to match_array(expected_result) if expected_result
              end
            end
          end

          context 'set to an invalid value' do
            let(:upgrade_status) { :some_invalid_status }

            it 'raises ArgumentError' do
              expect { execute }.to raise_error(ArgumentError)
            end
          end

          context 'set to nil' do
            let(:upgrade_status) { nil }

            it 'does not call with_upgrade_status' do
              expect(Ci::Runner).not_to receive(:with_upgrade_status)

              expect(execute).to match_array(Ci::Runner.all)
            end
          end
        end

        context 'by status' do
          Ci::Runner::AVAILABLE_STATUSES_INCL_DEPRECATED.each do |status|
            context "when status is #{status}" do
              let(:params) { { status_status: status } }

              it "calls the corresponding :#{status} scope on Ci::Runner" do
                expect(Ci::Runner).to receive(:with_status).with(status).and_call_original

                execute
              end
            end
          end
        end

        context 'by active status' do
          let(:params) { { active: active } }

          context 'when active is false' do
            let(:active) { false }

            it 'with active set as false calls the corresponding scope on Ci::Runner with false' do
              expect(Ci::Runner).to receive(:active).with(false).and_call_original

              execute
            end
          end

          context 'when active is true' do
            let(:active) { true }

            it 'with active set as true calls the corresponding scope on Ci::Runner with true' do
              expect(Ci::Runner).to receive(:active).with(true).and_call_original

              execute
            end
          end
        end

        context 'by runner type' do
          Ci::Runner.runner_types.each_key do |runner_type|
            context "when runner type is #{runner_type}" do
              let(:params) { { type_type: runner_type } }

              it "calls the corresponding scope on Ci::Runner" do
                expect(Ci::Runner).to receive(:with_runner_type).with(runner_type.to_sym).and_call_original

                execute
              end
            end
          end
        end

        context 'by tag_name' do
          let(:params) { { tag_name: %w[tag1 tag2] } }

          it 'calls the corresponding scope on Ci::Runner' do
            expect(Ci::Runner).to receive(:tagged_with).with(%w[tag1 tag2], like_search_enabled: true).and_call_original

            execute
          end
        end

        context 'by creator id' do
          let(:params) { { creator_id: '1' } }

          it 'calls the corresponding scope on Ci::Runner' do
            expect(Ci::Runner).to receive(:with_creator_id).with('1').and_call_original

            execute
          end
        end

        context 'by creator username' do
          let_it_be(:admin_runner) { create(:ci_runner, creator: admin) }

          let(:params) { { creator_username: admin.username } }

          it 'calls the corresponding scope on Ci::Runner' do
            expect(Ci::Runner).to receive(:with_creator_id).with(admin.id).and_call_original

            expect(execute).to match_array [admin_runner]
          end

          context 'when the username is not found and is empty' do
            let(:params) { { creator_username: "not a username" } }

            it 'does not call the scope' do
              expect(Ci::Runner).not_to receive(:with_creator_id)

              expect(execute).to be_empty
            end
          end
        end

        context 'by owner' do
          let_it_be(:admin2) { create(:admin) }
          let_it_be(:instance_runner) { create(:ci_runner, :instance) }
          let_it_be(:instance_admin_runner) { create(:ci_runner, :instance, creator: admin) }
          let_it_be(:instance_admin_runner2) { create(:ci_runner, :instance, creator: admin2) }
          let_it_be(:groups) { create_list(:group, 2) }
          let_it_be(:group_runner) { create(:ci_runner, :group, groups: [groups.first]) }
          let_it_be(:group_runner2) { create(:ci_runner, :group, groups: [groups.second]) }
          let_it_be(:projects) { create_list(:project, 2, group: groups.first) }
          let_it_be(:project_runner) { create(:ci_runner, :project, projects: [projects.first]) }
          let_it_be(:project_runner2) { create(:ci_runner, :project, projects: [projects.second]) }

          context 'when owner is set to administrators wildcard' do
            let(:current_user) { admin2 }
            let(:params) do
              { owner: { wildcard: :administrators } }
            end

            it 'calls corresponding scope and finds admin runner' do
              expect(Ci::Runner).to receive(:created_by_admins).and_call_original
              is_expected.to contain_exactly(instance_admin_runner, instance_admin_runner2)
            end
          end

          context 'when owner is set to first group full_path' do
            let(:params) do
              { owner: { full_path: groups.first.name } }
            end

            it 'calls corresponding scope and finds group' do
              expect(Ci::Runner).to receive(:belonging_to_group).and_call_original
              expect(execute).to contain_exactly group_runner
            end
          end

          context 'when owner is set to first project full_path' do
            let(:params) do
              { owner: { full_path: projects.first.full_path } }
            end

            it 'calls corresponding scope and finds project' do
              expect(Ci::Runner).to receive(:belonging_to_project).and_call_original
              expect(execute).to contain_exactly project_runner
            end
          end

          context 'when owner is set to empty path' do
            let(:params) do
              { owner: { full_path: '' } }
            end

            it 'does not filter' do
              is_expected.to contain_exactly(
                instance_admin_runner, instance_admin_runner2, instance_runner,
                group_runner, group_runner2, project_runner, project_runner2
              )
            end
          end

          context 'when owner is set to a non-existing path' do
            let(:params) do
              { owner: { full_path: "not-a-group-or-project" } }
            end

            it { is_expected.to be_empty }
          end
        end

        context 'by version' do
          let(:params) { { version_prefix: '15.' } }

          it 'calls the corresponding scope on Ci::Runner' do
            expect(Ci::Runner).to receive(:with_version_prefix).with('15.').and_call_original

            execute
          end
        end
      end

      context 'sorting' do
        let_it_be(:runner1) { create :ci_runner, created_at: '2018-07-12 07:00', contacted_at: 1.minute.ago, token_expires_at: '2022-02-15 07:00' }
        let_it_be(:runner2) { create :ci_runner, created_at: '2018-07-12 08:00', contacted_at: 3.minutes.ago, token_expires_at: '2022-02-15 06:00' }
        let_it_be(:runner3) { create :ci_runner, created_at: '2018-07-12 09:00', contacted_at: 2.minutes.ago }

        shared_examples 'sorts by created_at descending' do
          it 'sorts by created_at descending' do
            is_expected.to eq [runner3, runner2, runner1]
          end
        end

        context 'without sort param' do
          let(:params) { {} }

          it_behaves_like 'sorts by created_at descending'
        end

        %w[created_date created_at_desc].each do |sort|
          context "with sort param equal to #{sort}" do
            let(:params) { { sort: sort } }

            it_behaves_like 'sorts by created_at descending'
          end
        end

        context 'with sort param equal to created_at_asc' do
          let(:params) { { sort: 'created_at_asc' } }

          it 'sorts by created_at ascending' do
            is_expected.to eq [runner1, runner2, runner3]
          end
        end

        context 'with sort param equal to contacted_asc' do
          let(:params) { { sort: 'contacted_asc' } }

          it 'sorts by contacted_at ascending' do
            is_expected.to eq [runner2, runner3, runner1]
          end
        end

        context 'with sort param equal to contacted_desc' do
          let(:params) { { sort: 'contacted_desc' } }

          it 'sorts by contacted_at descending' do
            is_expected.to eq [runner1, runner3, runner2]
          end
        end

        context 'with sort param equal to token_expires_at_asc' do
          let(:params) { { sort: 'token_expires_at_asc' } }

          it 'sorts by contacted_at ascending' do
            is_expected.to eq [runner2, runner1, runner3]
          end
        end

        context 'with sort param equal to token_expires_at_desc' do
          let(:params) { { sort: 'token_expires_at_desc' } }

          it 'sorts by contacted_at descending' do
            is_expected.to eq [runner3, runner1, runner2]
          end
        end
      end
    end

    shared_examples 'executes as normal user' do
      let(:current_user) { create :user }
      let(:params) { {} }

      it 'raises Gitlab::Access::AccessDeniedError' do
        create :ci_runner
        create :ci_runner, :paused

        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
      it_behaves_like 'executes as admin'
    end

    context 'when admin mode setting is enabled' do
      context 'when in admin mode', :enable_admin_mode do
        it_behaves_like 'executes as admin'
      end

      context 'when not in admin mode' do
        it_behaves_like 'executes as normal user'
      end
    end

    context 'by non admin user' do
      it_behaves_like 'executes as normal user'
    end

    context 'when user is nil' do
      let(:current_user) { nil }

      it 'raises Gitlab::Access::AccessDeniedError' do
        create :ci_runner
        create :ci_runner, :paused

        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  context 'group' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group_1) { create(:group, parent: group) }
    let_it_be(:sub_group_2) { create(:group, parent: group) }
    let_it_be(:sub_group_3) { create(:group, parent: sub_group_1) }
    let_it_be(:sub_group_4) { create(:group, parent: sub_group_3) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_2) { create(:project, group: group) }
    let_it_be(:project_3) { create(:project, group: sub_group_1) }
    let_it_be(:project_4) { create(:project, group: sub_group_2) }
    let_it_be(:project_5) { create(:project, group: sub_group_3) }
    let_it_be(:project_6) { create(:project, group: sub_group_4) }
    let_it_be(:runner_instance) { create(:ci_runner, :instance, contacted_at: 13.minutes.ago) }
    let_it_be(:runner_group) { create(:ci_runner, :group, contacted_at: 12.minutes.ago, groups: [group]) }
    let_it_be(:runner_sub_group_1) { create(:ci_runner, :group, :paused, contacted_at: 11.minutes.ago, groups: [sub_group_1]) }
    let_it_be(:runner_sub_group_2) { create(:ci_runner, :group, contacted_at: 10.minutes.ago, groups: [sub_group_2]) }
    let_it_be(:runner_sub_group_3) { create(:ci_runner, :group, contacted_at: 9.minutes.ago, groups: [sub_group_3]) }
    let_it_be(:runner_sub_group_4) { create(:ci_runner, :group, contacted_at: 8.minutes.ago, groups: [sub_group_4]) }
    let_it_be(:runner_project_1) { create(:ci_runner, :project, contacted_at: 7.minutes.ago, projects: [project]) }
    let_it_be(:runner_project_2) { create(:ci_runner, :project, contacted_at: 6.minutes.ago, projects: [project_2]) }
    let_it_be(:runner_project_3) { create(:ci_runner, :project, contacted_at: 5.minutes.ago, description: 'runner_project_search', projects: [project, project_2]) }
    let_it_be(:runner_project_4) { create(:ci_runner, :project, contacted_at: 4.minutes.ago, projects: [project_3]) }
    let_it_be(:runner_project_5) { create(:ci_runner, :project, contacted_at: 3.minutes.ago, tag_list: %w[runner_tag], projects: [project_4]) }
    let_it_be(:runner_project_6) { create(:ci_runner, :project, contacted_at: 2.minutes.ago, projects: [project_5]) }
    let_it_be(:runner_project_7) { create(:ci_runner, :project, contacted_at: 1.minute.ago, projects: [project_6]) }
    let_it_be(:runner_manager_1) { create(:ci_runner_machine, runner: runner_sub_group_1, version: '15.11.0') }
    let_it_be(:runner_manager_2) { create(:ci_runner_machine, runner: runner_sub_group_2, version: '15.11.1') }
    let_it_be(:runner_manager_3) { create(:ci_runner_machine, runner: runner_sub_group_3, version: '15.10.1') }

    let(:current_user) { user }
    let(:target_group) { nil }
    let(:membership) { nil }
    let(:extra_params) { {} }
    let(:params) { { group: target_group, membership: membership, **extra_params }.compact }

    shared_examples 'membership equal to :descendants' do
      it 'returns all descendant runners' do
        is_expected.to contain_exactly(
          runner_project_7, runner_project_6, runner_project_5,
          runner_project_4, runner_project_3, runner_project_2,
          runner_project_1, runner_sub_group_4, runner_sub_group_3,
          runner_sub_group_2, runner_sub_group_1, runner_group)
      end
    end

    context 'with user is group maintainer or owner' do
      where(:user_role) do
        [GroupMember::OWNER, GroupMember::MAINTAINER]
      end

      with_them do
        before do
          group.add_member(current_user, user_role)
        end

        context 'with :group as target group' do
          let(:target_group) { group }

          context 'passing no membership params' do
            it_behaves_like 'membership equal to :descendants'
          end

          context 'with :descendants membership' do
            let(:membership) { :descendants }

            it_behaves_like 'membership equal to :descendants'
          end

          context 'with :direct membership' do
            let(:membership) { :direct }

            it 'returns runners belonging to group' do
              is_expected.to contain_exactly(runner_group)
            end
          end

          context 'with :all_available membership' do
            let(:membership) { :all_available }

            it 'returns runners available to group' do
              is_expected.to contain_exactly(
                runner_project_7, runner_project_6, runner_project_5,
                runner_project_4, runner_project_3, runner_project_2,
                runner_project_1, runner_sub_group_4, runner_sub_group_3,
                runner_sub_group_2, runner_sub_group_1, runner_group, runner_instance)
            end
          end

          context 'with unknown membership' do
            let(:membership) { :unsupported }

            it 'raises an error' do
              expect { subject }.to raise_error(ArgumentError, 'Invalid membership filter')
            end
          end

          context 'with nil group' do
            let(:target_group) { nil }

            it 'raises Gitlab::Access::AccessDeniedError' do
              # Query should run against all runners, however since user is not admin, we raise an error
              expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
            end
          end

          context 'with sort param' do
            let(:extra_params) { { sort: 'contacted_asc' } }

            it 'sorts by specified attribute' do
              expect(subject).to eq([runner_group, runner_sub_group_1, runner_sub_group_2,
                                    runner_sub_group_3, runner_sub_group_4, runner_project_1,
                                    runner_project_2, runner_project_3, runner_project_4,
                                    runner_project_5, runner_project_6, runner_project_7])
            end
          end

          context 'filtering' do
            context 'by search term' do
              let(:extra_params) { { search: 'runner_project_search' } }

              it 'returns correct runner' do
                expect(subject).to contain_exactly(runner_project_3)
              end
            end

            context 'by active status' do
              let(:extra_params) { { active: false } }

              it 'returns correct runner' do
                expect(subject).to contain_exactly(runner_sub_group_1)
              end
            end

            context 'by status' do
              let(:extra_params) { { status_status: 'paused' } }

              it 'returns correct runner' do
                expect(subject).to contain_exactly(runner_sub_group_1)
              end
            end

            context 'by tag_name' do
              let(:extra_params) { { tag_name: %w[runner_tag] } }

              it 'returns correct runner' do
                expect(subject).to contain_exactly(runner_project_5)
              end

              context 'when searching using part of the tag name' do
                let(:extra_params) { { tag_name: %w[unner] } }

                it 'returns correct runner' do
                  expect(subject).to contain_exactly(runner_project_5)
                end
              end
            end

            context 'by runner type' do
              let(:extra_params) { { type_type: 'project_type' } }

              it 'returns correct runners' do
                expect(subject).to eq([runner_project_7, runner_project_6,
                                      runner_project_5, runner_project_4,
                                      runner_project_3, runner_project_2, runner_project_1])
              end
            end

            context 'by version prefix' do
              context 'search by major version' do
                let(:extra_params) { { version_prefix: '15.' } }

                it 'returns correct runner' do
                  is_expected.to contain_exactly(runner_sub_group_1, runner_sub_group_2, runner_sub_group_3)
                end
              end

              context 'search by minor version' do
                let(:extra_params) { { version_prefix: '15.11.' } }

                it 'returns correct runner' do
                  is_expected.to contain_exactly(runner_sub_group_1, runner_sub_group_2)
                end
              end

              context 'search by patch version' do
                let(:extra_params) { { version_prefix: '15.11.1' } }

                it 'returns correct runner' do
                  is_expected.to contain_exactly(runner_sub_group_2)
                end
              end
            end
          end
        end
      end
    end

    context 'when user is group developer or below' do
      where(:user_role) do
        [GroupMember::DEVELOPER, GroupMember::REPORTER, GroupMember::GUEST]
      end

      with_them do
        before do
          group.add_member(current_user, user_role)
        end

        context 'with :sub_group_1 as target group' do
          let(:target_group) { sub_group_1 }

          it 'raises Gitlab::Access::AccessDeniedError' do
            expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end

        context 'with :group as target group' do
          let(:target_group) { group }

          it 'raises Gitlab::Access::AccessDeniedError' do
            expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
          end

          context 'with :all_available membership' do
            let(:membership) { :all_available }

            it 'raises Gitlab::Access::AccessDeniedError' do
              expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
            end
          end
        end
      end
    end

    context 'when user has no access' do
      it 'raises Gitlab::Access::AccessDeniedError' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when user is nil' do
      let(:current_user) { nil }

      it 'raises Gitlab::Access::AccessDeniedError' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    describe '#sort_key' do
      subject(:sort_key) do
        described_class.new(current_user: current_user, params: params.merge(group: group)).sort_key
      end

      context 'without params' do
        it { is_expected.to eq('created_at_desc') }
      end

      context 'with params' do
        let(:extra_params) { { sort: 'contacted_asc' } }

        it { is_expected.to eq('contacted_asc') }
      end
    end
  end

  context 'project' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:other_project) { create(:project) }

    let(:current_user) { user }
    let(:extra_params) { {} }
    let(:params) { { project: project, **extra_params }.compact }

    context 'with user as project maintainer' do
      let_it_be(:user) { create(:user, maintainer_of: project) }

      context 'with project runners' do
        let_it_be(:runner_project) { create(:ci_runner, :project, :online, projects: [project]) }

        it 'returns runners available to project' do
          is_expected.to contain_exactly(runner_project)
        end
      end

      context 'with ancestor group runners' do
        let_it_be(:runner_instance) { create(:ci_runner, :online) }
        let_it_be(:runner_group) { create(:ci_runner, :group, :online, groups: [group]) }

        it 'returns runners available to project' do
          is_expected.to contain_exactly(runner_instance, runner_group)
        end
      end

      context 'with allowed shared runners' do
        let_it_be(:runner_instance) { create(:ci_runner, :instance, :online) }

        it 'returns runners available to project' do
          expect(subject).to contain_exactly(runner_instance)
        end
      end

      context 'with project, ancestor group, and allowed shared runners' do
        let_it_be(:runner_project) { create(:ci_runner, :project, projects: [project]) }
        let_it_be(:runner_group) { create(:ci_runner, :group, groups: [group]) }
        let_it_be(:runner_instance) { create(:ci_runner, :instance) }

        it 'returns runners available to project' do
          expect(subject).to contain_exactly(runner_project, runner_group, runner_instance)
        end
      end

      context 'filtering' do
        let_it_be(:runner_instance_paused) { create(:ci_runner, :instance, :paused, :offline) }
        let_it_be(:runner_instance_active) { create(:ci_runner, :instance, :online) }
        let_it_be(:runner_project_active) { create(:ci_runner, :project, :offline, projects: [project]) }
        let_it_be(:runner_project_paused) { create(:ci_runner, :project, :paused, :online, projects: [project]) }
        let_it_be(:runner_other_project_paused) { create(:ci_runner, :project, :paused, :online, projects: [other_project]) }
        let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner_instance_paused, version: '15.10.0') }

        context 'by search term' do
          let_it_be(:runner_project_1) { create(:ci_runner, :project, :online, description: 'runner_project_search', projects: [project]) }
          let_it_be(:runner_project_2) { create(:ci_runner, :project, :online, description: 'runner_project', projects: [project]) }
          let_it_be(:runner_another_project) { create(:ci_runner, :project, :online, description: 'runner_project_search', projects: [other_project]) }

          let(:extra_params) { { search: 'runner_project_search' } }

          it 'returns the correct runner' do
            expect(subject).to contain_exactly(runner_project_1)
          end
        end

        context 'by active status' do
          let(:extra_params) { { active: false } }

          it 'returns the correct runners' do
            expect(subject).to contain_exactly(runner_instance_paused, runner_project_paused)
          end
        end

        context 'by status' do
          let(:extra_params) { { status_status: 'paused' } }

          it 'returns correct runner' do
            expect(subject).to contain_exactly(runner_instance_paused, runner_project_paused)
          end
        end

        context 'by tag_name' do
          let_it_be(:runner_project_1) { create(:ci_runner, :project, tag_list: %w[runner_tag], projects: [project]) }
          let_it_be(:runner_project_2) { create(:ci_runner, :project, tag_list: %w[other_tag], projects: [project]) }
          let_it_be(:runner_other_project) { create(:ci_runner, :project, tag_list: %w[runner_tag], projects: [other_project]) }

          let(:extra_params) { { tag_name: %w[runner_tag] } }

          it 'returns correct runner' do
            expect(subject).to contain_exactly(runner_project_1)
          end
        end

        context 'by runner type' do
          let(:extra_params) { { type_type: 'project_type' } }

          it 'returns correct runners' do
            expect(subject).to contain_exactly(runner_project_active, runner_project_paused)
          end
        end

        context 'by creator' do
          let_it_be(:creator) { create(:user) }
          let_it_be(:runner_with_creator) { create(:ci_runner, creator: creator) }

          let(:extra_params) { { creator_id: creator.id } }

          it 'returns correct runners' do
            is_expected.to contain_exactly(runner_with_creator)
          end
        end

        context 'by version prefix' do
          let(:extra_params) { { version_prefix: '15.' } }

          it 'returns correct runners' do
            is_expected.to contain_exactly(runner_instance_paused)
          end
        end
      end
    end

    context 'with user as project developer' do
      let(:user) { create(:user, developer_of: project) }

      it 'raises Gitlab::Access::AccessDeniedError' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when user is nil' do
      let_it_be(:user) { nil }

      it 'raises Gitlab::Access::AccessDeniedError' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
