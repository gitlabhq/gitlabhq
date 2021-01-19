# frozen_string_literal: true

require "spec_helper"

RSpec.describe InviteMembersHelper do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let(:owner) { project.owner }

  context 'with project' do
    before do
      assign(:project, project)
    end

    describe "#can_invite_members_for_project?" do
      context 'when the user can_import_members' do
        before do
          allow(helper).to receive(:can_import_members?).and_return(true)
        end

        it 'returns true' do
          expect(helper.can_invite_members_for_project?(project)).to eq true
          expect(helper).to have_received(:can_import_members?)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(invite_members_group_modal: false)
          end

          it 'returns false' do
            expect(helper.can_invite_members_for_project?(project)).to eq false
            expect(helper).not_to have_received(:can_import_members?)
          end
        end
      end

      context 'when the user can not invite members' do
        before do
          expect(helper).to receive(:can_import_members?).and_return(false)
        end

        it 'returns false' do
          expect(helper.can_invite_members_for_project?(project)).to eq false
        end
      end
    end

    describe "#directly_invite_members?" do
      context 'when the user is an owner' do
        before do
          allow(helper).to receive(:current_user) { owner }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_a) { false }

          expect(helper.directly_invite_members?).to eq false
        end

        it 'returns true' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_a) { true }

          expect(helper.directly_invite_members?).to eq true
        end
      end

      context 'when the user is a developer' do
        before do
          allow(helper).to receive(:current_user) { developer }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_a) { true }

          expect(helper.directly_invite_members?).to eq false
        end
      end
    end

    describe "#indirectly_invite_members?" do
      context 'when a user is a developer' do
        before do
          allow(helper).to receive(:current_user) { developer }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_b) { false }

          expect(helper.indirectly_invite_members?).to eq false
        end

        it 'returns true' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_b) { true }

          expect(helper.indirectly_invite_members?).to eq true
        end
      end

      context 'when a user is an owner' do
        before do
          allow(helper).to receive(:current_user) { owner }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_version_b) { true }

          expect(helper.indirectly_invite_members?).to eq false
        end
      end
    end
  end

  context 'with group' do
    let_it_be(:group) { create(:group) }

    describe "#can_invite_members_for_group?" do
      include Devise::Test::ControllerHelpers

      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
        allow(helper).to receive(:current_user) { user }
      end

      context 'when the user can_import_members' do
        before do
          allow(helper).to receive(:can?).with(user, :admin_group_member, group).and_return(true)
        end

        it 'returns true' do
          expect(helper.can_invite_members_for_group?(group)).to eq true
          expect(helper).to have_received(:can?).with(user, :admin_group_member, group)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(invite_members_group_modal: false)
          end

          it 'returns false' do
            stub_feature_flags(invite_members_group_modal: false)

            expect(helper.can_invite_members_for_group?(group)).to eq false
            expect(helper).not_to have_received(:can?)
          end
        end
      end

      context 'when the user can not invite members' do
        before do
          expect(helper).to receive(:can?).with(user, :admin_group_member, group).and_return(false)
        end

        it 'returns false' do
          expect(helper.can_invite_members_for_group?(group)).to eq false
        end
      end
    end

    describe "#invite_group_members?" do
      context 'when the user is an owner' do
        before do
          group.add_owner(owner)
          allow(helper).to receive(:current_user) { owner }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { false }

          expect(helper.invite_group_members?(group)).to eq false
        end

        it 'returns true' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { true }

          expect(helper.invite_group_members?(group)).to eq true
        end
      end

      context 'when the user is a developer' do
        before do
          group.add_developer(developer)
          allow(helper).to receive(:current_user) { developer }
        end

        it 'returns false' do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_empty_group_version_a) { true }

          expect(helper.invite_group_members?(group)).to eq false
        end
      end
    end
  end

  describe '#dropdown_invite_members_link' do
    shared_examples_for 'dropdown invite members link' do
      let(:link_regex) do
        /data-track-event="click_link".*data-track-property="_track_property_".*Invite members/
      end

      before do
        allow(helper).to receive(:experiment_tracking_category_and_group) { '_track_property_' }
        allow(helper).to receive(:tracking_label)
        allow(helper).to receive(:current_user) { owner }
      end

      it 'records the experiment' do
        allow(helper).to receive(:experiment_enabled?)

        helper.dropdown_invite_members_link(form_model)

        expect(helper).to have_received(:experiment_tracking_category_and_group).with(:invite_members_new_dropdown)
      end

      context 'with experiment enabled' do
        before do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_new_dropdown) { true }
        end

        it 'returns link' do
          link = helper.dropdown_invite_members_link(form_model)

          expect(link).to match(link_regex)
          expect(link).to include(link_href)
          expect(link).to include('gl-emoji')
        end
      end

      context 'with no experiment enabled' do
        before do
          allow(helper).to receive(:experiment_enabled?).with(:invite_members_new_dropdown) { false }
        end

        it 'returns link' do
          link = helper.dropdown_invite_members_link(form_model)

          expect(link).to match(link_regex)
          expect(link).to include(link_href)
          expect(link).not_to include('gl-emoji')
        end
      end
    end

    context 'with a project' do
      let_it_be(:form_model) { project }
      let(:link_href) { "href=\"#{project_project_members_path(form_model)}\"" }

      it_behaves_like 'dropdown invite members link'
    end

    context 'with a group' do
      let_it_be(:form_model) { create(:group) }
      let(:link_href) { "href=\"#{group_group_members_path(form_model)}\"" }

      it_behaves_like 'dropdown invite members link'
    end
  end
end
