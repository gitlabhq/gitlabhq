# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'General settings visibility levels', :js, :aggregate_failures, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user).tap { |user| group.add_owner(user) } }

  before do
    sign_in(user)
  end

  context 'with parent group internal' do
    let_it_be(:parent_group) { create(:group, :internal) }
    let_it_be(:group) { create(:group, :internal, parent: parent_group) }
    let_it_be(:user) { create(:user).tap { |user| group.add_owner(user) } }

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_content('Visibility level')

      expect(page).to have_field("Private",  checked: false, disabled: false)
      expect(page).to have_field("Internal", checked: true,  disabled: false)
      expect(page).to have_field("Public",   checked: false, disabled: true)

      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Private')
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')
      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Public',
        popover_content: 'This visibility level is not allowed ' \
          'because the parent group has a more restrictive visibility level.'
      )
    end
  end

  context 'with internal child project in group' do
    let_it_be(:project) { create(:project, :internal, group: group) }

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_field("Private",  checked: false, disabled: true)
      expect(page).to have_field("Internal", checked: false, disabled: false)
      expect(page).to have_field("Public",   checked: true,  disabled: false)

      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Private',
        popover_content: "This visibility level is not allowed " \
          "because a child of #{group.name} has a less restrictive visibility level. Learn more."
      )
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Public')
    end
  end

  context 'without restricted visibility levels' do
    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_content('Visibility level')

      expect(page).to have_field("Private",  checked: false, disabled: false)
      expect(page).to have_field("Internal", checked: false, disabled: false)
      expect(page).to have_field("Public",   checked: true,  disabled: false)

      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Private')
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Public')
    end
  end

  context 'with restricted visibility level public' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_field("Private",  checked: false, disabled: false)
      expect(page).to have_field("Internal", checked: false, disabled: false)
      expect(page).to have_field("Public",   checked: true,  disabled: true)

      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Private')
      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')
      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Public',
        popover_content: 'This visibility level has been restricted by your administrator.'
      )
    end

    context 'with private project in group' do
      let_it_be(:project) { create(:project, :private, group: group) }

      it 'shows each visibility level in correct field state' do
        visit edit_group_path(group)

        expect(page).to have_field("Private",  checked: false, disabled: false)
        expect(page).to have_field("Internal", checked: false, disabled: false)
        expect(page).to have_field("Public",   checked: true,  disabled: true)

        expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Private')
        expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')
        expect_popover_for_disallowed_visibility_level(
          visibility_level_label_text: 'Public',
          popover_content: 'This visibility level has been restricted by your administrator.'
        )
      end
    end

    context 'with public project in group' do
      let_it_be(:project) { create(:project, :public, group: group) }

      it 'shows each visibility level in correct field state' do
        visit edit_group_path(group)

        expect(page).to have_field("Private",  checked: false, disabled: true)
        expect(page).to have_field("Internal", checked: false, disabled: true)
        expect(page).to have_field("Public",   checked: true,  disabled: true)

        expect_popover_for_disallowed_visibility_level(
          visibility_level_label_text: 'Private',
          popover_content: "This visibility level is not allowed " \
            "because a child of #{group.name} has a less restrictive visibility level. Learn more."
        )

        expect_popover_for_disallowed_visibility_level(
          visibility_level_label_text: 'Internal',
          popover_content: "This visibility level is not allowed " \
            "because a child of #{group.name} has a less restrictive visibility level. Learn more."
        )

        expect_popover_for_disallowed_visibility_level(
          visibility_level_label_text: 'Public',
          popover_content: 'This visibility level has been restricted by your administrator.'
        )
      end
    end
  end

  context 'with multiple restricted visibility levels "Public" and "Private"' do
    let_it_be(:project) { create(:project, :internal, group: group) }

    before do
      stub_application_setting(
        restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::PRIVATE]
      )
    end

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_field("Private",  checked: false, disabled: true)
      expect(page).to have_field("Internal", checked: false, disabled: false)
      expect(page).to have_field("Public",   checked: true,  disabled: true)

      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Private',
        popover_content: 'This visibility level has been restricted by your administrator.'
      )

      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Internal')

      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Public',
        popover_content: 'This visibility level has been restricted by your administrator.'
      )
    end
  end

  context 'with public organization' do
    let_it_be(:public_organization) { create(:organization, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, organization: public_organization, owners: user) }

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_content('Visibility level')

      expect(page).to have_field("Private",  checked: false, disabled: false)
      expect(page).to have_field("Internal", checked: false, disabled: false)
      expect(page).to have_field("Public",   checked: true, disabled: false)
    end
  end

  context 'with private organization' do
    let_it_be(:private_organization) { create(:organization, :private) }
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :private, organization: private_organization, owners: user) }

    it 'shows each visibility level in correct field state' do
      visit edit_group_path(group)

      expect(page).to have_content('Visibility level')

      expect(page).to have_field("Private",  checked: true, disabled: false)
      expect(page).to have_field("Internal", checked: false, disabled: true)
      expect(page).to have_field("Public",   checked: false, disabled: true)

      expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text: 'Private')
      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Internal',
        popover_content: 'This visibility level is not allowed ' \
          'because the organization has a more restrictive visibility level.'
      )
      expect_popover_for_disallowed_visibility_level(
        visibility_level_label_text: 'Public',
        popover_content: 'This visibility level is not allowed ' \
          'because the organization has a more restrictive visibility level.'
      )
    end
  end

  def expect_popover_for_disallowed_visibility_level(visibility_level_label_text:, popover_content:)
    # Checking that a popover content is not visible before hovering
    expect(page).not_to have_content(popover_content)

    within('label', text: visibility_level_label_text) do
      find('[data-testid=visibility-level-not-allowed-popover]').hover
    end

    page.within('.gl-popover') do
      expect(page).to have_content('Visibility level not allowed')
      expect(page).to have_content(popover_content)
    end

    # Move cursor to another element to hide the popover
    find('label', text: visibility_level_label_text).hover
  end

  def expect_no_popover_for_disallowed_visibility_level(visibility_level_label_text:)
    within('label', text: visibility_level_label_text) do
      expect(page).not_to have_selector('[data-testid=visibility-level-not-allowed-popover]')
    end

    expect(page).not_to have_selector('.gl-popover')
  end
end
