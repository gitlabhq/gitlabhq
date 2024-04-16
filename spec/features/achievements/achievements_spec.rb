# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Achievements", :js, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public, maintainers: user) }
  let_it_be(:achievement1) { create(:achievement, namespace: group) }
  let_it_be(:achievement2) { create(:achievement, namespace: group, description: 'Achievement description') }

  before do
    sign_in(user)
  end

  it 'displays groups achievements' do
    visit(group_achievements_path(group))

    expect(page).to have_content(achievement1.name)
      .and have_content(achievement2.name)
      .and have_content(achievement2.description)
  end

  context 'when creating a new achievement' do
    before do
      visit(new_group_achievement_path(group))
    end

    it 'returns to the achievements list, displays the new achievement and toast' do
      achievement_name = 'Superstar'
      achievement_desc = 'A legend!'
      fill_in('Name', with: achievement_name)
      fill_in('Description', with: achievement_desc)
      attach_file('avatar_file', Rails.root.join('spec/fixtures/dk.png'), visible: false)

      click_button('Save changes')

      expect(page).to have_current_path("#{group_achievements_path(group)}/")
        .and have_content(achievement_name)
        .and have_content(achievement_desc)
        .and have_content(achievement2.description)
        .and have_content('Achievement has been added.')

      # TODO: Look for this avatar on the page once we start to show them!
      expect(Achievements::Achievement.last.avatar_url).not_to be_nil
    end

    it 'validates required fields' do
      click_button('Save changes')

      expect(page).to have_content('Achievement name is required.')
    end

    it 'validates field lengths' do
      fill_in('Name', with: 'x' * 256)
      fill_in('Description', with: 'y' * 1025)
      click_button('Save changes')

      expect(page).to have_content('Achievement name cannot be longer than 255 characters.')
        .and have_content('Achievement description cannot be longer than 1024 characters.')
    end

    context 'when closing the form' do
      it 'returns to the achievements list and does not display toast' do
        find('button[aria-label="Close drawer"]').click

        expect(page).to have_current_path("#{group_achievements_path(group)}/")
        expect(page).not_to have_content('Achievement has been added.')
      end
    end
  end
end
