# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nav::NewDropdownHelper do
  describe '#new_dropdown_view_model' do
    let_it_be(:user) { build_stubbed(:user) }

    let(:current_user) { user }
    let(:current_project) { nil }
    let(:current_group) { nil }

    let(:with_can_create_project) { false }
    let(:with_can_create_group) { false }
    let(:with_can_create_snippet) { false }
    let(:with_invite_members_experiment) { false }
    let(:with_invite_members_experiment_enabled) { false }

    let(:subject) { helper.new_dropdown_view_model(project: current_project, group: current_group) }

    def expected_menu_section(title:, menu_item:)
      [
        {
          title: title,
          menu_items: [menu_item]
        }
      ]
    end

    before do
      allow(::Gitlab::Experimentation).to receive(:active?).with(:invite_members_new_dropdown) { with_invite_members_experiment }
      allow(helper).to receive(:experiment_enabled?).with(:invite_members_new_dropdown) { with_invite_members_experiment_enabled }
      allow(helper).to receive(:tracking_label) { 'test_tracking_label' }
      allow(helper).to receive(:experiment_tracking_category_and_group) { |x| x }

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?) { false }

      allow(user).to receive(:can_create_project?) { with_can_create_project }
      allow(user).to receive(:can_create_group?) { with_can_create_group }
      allow(user).to receive(:can?).with(:create_snippet) { with_can_create_snippet }
    end

    shared_examples 'invite member link shared example' do
      it 'shows invite member link' do
        expect(subject[:menu_sections]).to eq(
          expected_menu_section(
            title: expected_title,
            menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
              id: 'invite',
              title: 'Invite members',
              href: expected_href,
              data: {
                track_event: 'click_link',
                track_label: 'test_tracking_label',
                track_property: :invite_members_new_dropdown
              }
            )
          )
        )
      end

      context 'with experiment enabled' do
        let(:with_invite_members_experiment_enabled) { true }

        it 'shows emoji with invite member link' do
          expect(subject[:menu_sections]).to match(
            expected_menu_section(
              title: expected_title,
              menu_item: a_hash_including(
                emoji: 'shaking_hands'
              )
            )
          )
        end
      end
    end

    it 'has title' do
      expect(subject[:title]).to eq('New...')
    end

    context 'when current_user is nil (anonymous)' do
      let(:current_user) { nil }

      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'when group and project are nil' do
      it 'has no menu sections' do
        expect(subject[:menu_sections]).to eq([])
      end

      context 'when can create project' do
        let(:with_can_create_project) { true }

        it 'has project menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'GitLab',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'general_new_project',
                title: 'New project/repository',
                href: '/projects/new',
                data: { track_event: 'click_link_new_project', track_label: 'plus_menu_dropdown', qa_selector: 'global_new_project_link' }
              )
            )
          )
        end
      end

      context 'when can create group' do
        let(:with_can_create_group) { true }

        it 'has group menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'GitLab',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'general_new_group',
                title: 'New group',
                href: '/groups/new',
                data: { track_event: 'click_link_new_group', track_label: 'plus_menu_dropdown' }
              )
            )
          )
        end
      end

      context 'when can create snippet' do
        let(:with_can_create_snippet) { true }

        it 'has new snippet menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'GitLab',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'general_new_snippet',
                title: 'New snippet',
                href: '/-/snippets/new',
                data: { track_event: 'click_link_new_snippet_parent', track_label: 'plus_menu_dropdown', qa_selector: 'global_new_snippet_link' }
              )
            )
          )
        end
      end
    end

    context 'with persisted group' do
      let_it_be(:group) { build_stubbed(:group) }

      let(:current_group) { group }
      let(:with_can_create_projects_in_group) { false }
      let(:with_can_create_subgroup_in_group) { false }
      let(:with_can_admin_in_group) { false }

      before do
        allow(group).to receive(:persisted?) { true }
        allow(helper).to receive(:can?).with(current_user, :create_projects, group) { with_can_create_projects_in_group }
        allow(helper).to receive(:can?).with(current_user, :create_subgroup, group) { with_can_create_subgroup_in_group }
        allow(helper).to receive(:can?).with(current_user, :admin_group_member, group) { with_can_admin_in_group }
      end

      it 'has no menu sections' do
        expect(subject[:menu_sections]).to eq([])
      end

      context 'when can create projects in group' do
        let(:with_can_create_projects_in_group) { true }

        it 'has new project menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'This group',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'new_project',
                title: 'New project/repository',
                href: "/projects/new?namespace_id=#{group.id}",
                data: { track_event: 'click_link_new_project_group', track_label: 'plus_menu_dropdown' }
              )
            )
          )
        end
      end

      context 'when can create subgroup' do
        let(:with_can_create_subgroup_in_group) { true }

        it 'has new subgroup menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'This group',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'new_subgroup',
                title: 'New subgroup',
                href: "/groups/new?parent_id=#{group.id}",
                data: { track_event: 'click_link_new_subgroup', track_label: 'plus_menu_dropdown' }
              )
            )
          )
        end
      end

      context 'when can invite members' do
        let(:with_can_admin_in_group) { true }
        let(:with_invite_members_experiment) { true }
        let(:expected_title) { 'This group' }
        let(:expected_href) { "/groups/#{group.full_path}/-/group_members" }

        it_behaves_like 'invite member link shared example'
      end
    end

    context 'with persisted project' do
      let_it_be(:project) { build_stubbed(:project) }
      let_it_be(:merge_project) { build_stubbed(:project) }

      let(:current_project) { project }
      let(:with_show_new_issue_link) { false }
      let(:with_merge_project) { nil }
      let(:with_can_create_snippet_in_project) { false }
      let(:with_can_import_members) { false }

      before do
        allow(helper).to receive(:show_new_issue_link?).with(project) { with_show_new_issue_link }
        allow(helper).to receive(:merge_request_source_project_for_project).with(project) { with_merge_project }
        allow(helper).to receive(:can?).with(user, :create_snippet, project) { with_can_create_snippet_in_project }
        allow(helper).to receive(:can_import_members?) { with_can_import_members }
      end

      it 'has no menu sections' do
        expect(subject[:menu_sections]).to eq([])
      end

      context 'with show_new_issue_link?' do
        let(:with_show_new_issue_link) { true }

        it 'shows new issue menu item' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'This project',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'new_issue',
                title: 'New issue',
                href: "/#{project.path_with_namespace}/-/issues/new",
                data: { track_event: 'click_link_new_issue', track_label: 'plus_menu_dropdown', qa_selector: 'new_issue_link' }
              )
            )
          )
        end
      end

      context 'with merge project' do
        let(:with_merge_project) { merge_project }

        it 'shows merge project' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'This project',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'new_mr',
                title: 'New merge request',
                href: "/#{merge_project.path_with_namespace}/-/merge_requests/new",
                data: { track_event: 'click_link_new_mr', track_label: 'plus_menu_dropdown' }
              )
            )
          )
        end
      end

      context 'when can create snippet' do
        let(:with_can_create_snippet_in_project) { true }

        it 'shows new snippet' do
          expect(subject[:menu_sections]).to eq(
            expected_menu_section(
              title: 'This project',
              menu_item: ::Gitlab::Nav::TopNavMenuItem.build(
                id: 'new_snippet',
                title: 'New snippet',
                href: "/#{project.path_with_namespace}/-/snippets/new",
                data: { track_event: 'click_link_new_snippet_project', track_label: 'plus_menu_dropdown' }
              )
            )
          )
        end
      end

      context 'when invite members experiment' do
        let(:with_invite_members_experiment) { true }
        let(:with_can_import_members) { true }
        let(:expected_title) { 'This project' }
        let(:expected_href) { "/#{project.path_with_namespace}/-/project_members" }

        it_behaves_like 'invite member link shared example'
      end
    end
  end
end
