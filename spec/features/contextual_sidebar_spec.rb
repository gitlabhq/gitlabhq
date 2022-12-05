# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contextual sidebar', :js, feature_category: :remote_development do
  context 'when context is a project' do
    let_it_be(:project) { create(:project) }

    let(:user) { project.first_owner }

    before do
      sign_in(user)
    end

    context 'when analyzing the menu' do
      before do
        visit project_path(project)
      end

      it 'shows flyout navs when collapsed or expanded apart from on the active item when expanded', :aggregate_failures do
        expect(page).not_to have_selector('.js-sidebar-collapsed')

        find('.rspec-link-pipelines').hover

        expect(page).to have_selector('.is-showing-fly-out')

        find('.rspec-project-link').hover

        expect(page).not_to have_selector('.is-showing-fly-out')

        find('.rspec-toggle-sidebar').click

        find('.rspec-link-pipelines').hover

        expect(page).to have_selector('.is-showing-fly-out')

        find('.rspec-project-link').hover

        expect(page).to have_selector('.is-showing-fly-out')
      end
    end

    context 'with invite_members_in_side_nav experiment', :experiment do
      it 'allows opening of modal for the candidate experience' do
        stub_experiments(invite_members_in_side_nav: :candidate)
        expect(experiment(:invite_members_in_side_nav)).to track(:assignment)
                                                             .with_context(group: project.group)
                                                             .on_next_instance

        visit project_path(project)

        page.within '[data-test-id="side-nav-invite-members"' do
          find('[data-test-id="invite-members-button"').click
        end

        expect(page).to have_content("You're inviting members to the")
      end

      it 'does not have invite members link in side nav for the control experience' do
        stub_experiments(invite_members_in_side_nav: :control)
        expect(experiment(:invite_members_in_side_nav)).to track(:assignment)
                                                             .with_context(group: project.group)
                                                             .on_next_instance

        visit project_path(project)

        expect(page).not_to have_css('[data-test-id="side-nav-invite-members"')
      end
    end
  end

  context 'when context is a group' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) do
      create(:group).tap do |g|
        g.add_owner(user)
      end
    end

    before do
      sign_in(user)
    end

    context 'with invite_members_in_side_nav experiment', :experiment do
      it 'allows opening of modal for the candidate experience' do
        stub_experiments(invite_members_in_side_nav: :candidate)
        expect(experiment(:invite_members_in_side_nav)).to track(:assignment)
                                                             .with_context(group: group)
                                                             .on_next_instance

        visit group_path(group)

        page.within '[data-test-id="side-nav-invite-members"' do
          find('[data-test-id="invite-members-button"').click
        end

        expect(page).to have_content("You're inviting members to the")
      end

      it 'does not have invite members link in side nav for the control experience' do
        stub_experiments(invite_members_in_side_nav: :control)
        expect(experiment(:invite_members_in_side_nav)).to track(:assignment)
                                                             .with_context(group: group)
                                                             .on_next_instance

        visit group_path(group)

        expect(page).not_to have_css('[data-test-id="side-nav-invite-members"')
      end
    end
  end
end
