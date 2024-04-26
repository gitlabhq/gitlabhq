# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Overview tab on a user profile', :js, feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:contributed_project) { create(:project, :public, :repository) }

  def push_code_contribution
    event = create(:push_event, project: contributed_project, author: user)

    create(
      :push_event_payload,
      event: event,
      commit_from: '11f9ac0a48b62cef25eedede4c1819964f08d5ce',
      commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
      commit_count: 3,
      ref: 'master'
    )
  end

  before do
    stub_feature_flags(profile_tabs_vue: false)
    sign_in user
  end

  shared_context 'visit overview tab' do
    before do
      visit user.username
      click_nav user.name
    end
  end

  describe 'activities section' do
    describe 'user has no activities' do
      include_context 'visit overview tab'

      it 'does not show any entries in the list of activities' do
        page.within('.activities-block') do
          expect(page).to have_selector('.loading', visible: false)
          expect(page).to have_content('Join or create a group to start contributing by commenting on issues or submitting merge requests!')
          expect(page).not_to have_selector('.event-item')
        end
      end

      it 'does not show a link to the activity list' do
        expect(find('#js-overview .activities-block')).to have_selector('.js-view-all', visible: false)
      end
    end

    describe 'user has 3 activities' do
      before do
        3.times { push_code_contribution }
      end

      include_context 'visit overview tab'

      it 'display 3 entries in the list of activities' do
        expect(find('#js-overview')).to have_selector('.event-item', count: 3)
      end
    end

    describe 'user has 15 activities' do
      before do
        16.times { push_code_contribution }
      end

      include_context 'visit overview tab'

      it 'displays 15 entries in the list of activities' do
        expect(find('#js-overview')).to have_selector('.event-item', count: 15)
      end

      it 'shows a link to the activity list' do
        expect(find('#js-overview .activities-block')).to have_selector('.js-view-all', visible: true)
      end

      it 'links to the activity tab' do
        page.within('.activities-block') do
          find('.js-view-all').click
          wait_for_requests
          expect(URI.parse(current_url).path).to eq("/users/#{user.username}/activity")
        end
      end
    end
  end

  describe 'projects section' do
    describe 'user has a personal project' do
      before do
        create(:project, :private, namespace: user.namespace, creator: user) { |p| p.add_maintainer(user) }
      end

      include_context 'visit overview tab'

      it 'shows one entry in the list of projects' do
        page.within('.projects-block') do
          expect(page).to have_selector('.gl-card', count: 1)
        end
      end

      it 'shows a link to the project list' do
        expect(find('#js-overview .projects-block')).to have_selector('.js-view-all', visible: true)
      end

      it 'shows projects in "card mode"' do
        page.within('#js-overview .projects-block') do
          expect(find('.js-projects-list-holder')).to have_css('.gl-card')
        end
      end
    end

    describe 'user has more than ten personal projects' do
      before do
        create_list(:project, 11, :private, namespace: user.namespace, creator: user) do |project|
          project.add_maintainer(user)
        end
      end

      include_context 'visit overview tab'

      it 'shows max. 3 entries in the list of projects' do
        page.within('.projects-block') do
          expect(page).to have_selector('.gl-card', count: 3)
        end
      end

      it 'shows a link to the project list' do
        expect(find('#js-overview .projects-block')).to have_selector('.js-view-all', visible: true)
      end

      it 'does not show pagination' do
        page.within('.projects-block') do
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end
  end

  describe 'followers section' do
    describe 'user has no followers' do
      before do
        visit user.username
        click_nav 'Followers'
      end

      it 'shows an empty followers list with an info message' do
        page.within('#followers') do
          expect(page).to have_content('You do not have any followers')
          expect(page).not_to have_selector('.gl-card.gl-mb-5')
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end

    describe 'user has less then 20 followers' do
      let(:follower) { create(:user) }

      before do
        follower.follow(user)
        visit user.username
        click_nav 'Followers'
      end

      it 'shows followers' do
        page.within('#followers') do
          expect(page).to have_content(follower.name)
          expect(page).to have_selector('.gl-card.gl-mb-5')
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end

    describe 'user has more then 20 followers' do
      let(:other_users) { create_list(:user, 21) }

      before do
        other_users.each do |follower|
          follower.follow(user)
        end

        visit user.username
        click_nav 'Followers'
      end

      it 'shows paginated followers' do
        page.within('#followers') do
          other_users.each_with_index do |follower, i|
            break if i == 20

            expect(page).to have_content(follower.name)
          end
          expect(page).to have_selector('.gl-card.gl-mb-5')
          expect(page).to have_selector('.gl-pagination')
          expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
        end
      end
    end
  end

  describe 'following section' do
    describe 'user is not following others' do
      before do
        visit user.username
        click_nav 'Following'
      end

      it 'shows an empty following list with an info message' do
        page.within('#following') do
          expect(page).to have_content('You are not following other users')
          expect(page).not_to have_selector('.gl-card.gl-mb-5')
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end

    describe 'user is following less then 20 people' do
      let(:followee) { create(:user) }

      before do
        user.follow(followee)
        visit user.username
        click_nav 'Following'
      end

      it 'shows following user' do
        page.within('#following') do
          expect(page).to have_content(followee.name)
          expect(page).to have_selector('.gl-card.gl-mb-5')
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end

    describe 'user is following more then 20 people' do
      let(:other_users) { create_list(:user, 21) }

      before do
        other_users.each do |followee|
          user.follow(followee)
        end

        visit user.username
        click_nav 'Following'
      end

      it 'shows paginated following' do
        page.within('#following') do
          other_users.each_with_index do |followee, i|
            break if i == 20

            expect(page).to have_content(followee.name)
          end
          expect(page).to have_selector('.gl-card.gl-mb-5')
          expect(page).to have_selector('.gl-pagination')
          expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
        end
      end
    end
  end

  describe 'bot user' do
    let(:bot_user) { create(:user, user_type: :security_bot) }

    shared_context "visit bot's overview tab" do
      before do
        visit bot_user.username
        click_nav bot_user.name
      end
    end

    include_context "visit bot's overview tab"

    it "activity panel's title is 'Activity'" do
      page.within('.activities-block') do
        expect(page).to have_text('Activity')
      end
    end

    it 'does not show projects panel' do
      expect(page).not_to have_selector('.projects-block')
    end
  end

  private

  def click_nav(title)
    within_testid('super-sidebar') do
      click_link title
    end
    wait_for_requests
  end
end
