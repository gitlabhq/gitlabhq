# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Overview tab on a user profile', :js do
  let(:user) { create(:user) }
  let(:contributed_project) { create(:project, :public, :repository) }

  def push_code_contribution
    event = create(:push_event, project: contributed_project, author: user)

    create(:push_event_payload,
           event: event,
           commit_from: '11f9ac0a48b62cef25eedede4c1819964f08d5ce',
           commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
           commit_count: 3,
           ref: 'master')
  end

  before do
    sign_in user
  end

  shared_context 'visit overview tab' do
    before do
      visit user.username
      page.find('.js-overview-tab a').click
      wait_for_requests
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

    describe 'user has 11 activities' do
      before do
        11.times { push_code_contribution }
      end

      include_context 'visit overview tab'

      it 'displays 10 entries in the list of activities' do
        expect(find('#js-overview')).to have_selector('.event-item', count: 10)
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
    describe 'user has no personal projects' do
      include_context 'visit overview tab'

      it 'shows an empty project list with an info message' do
        page.within('.projects-block') do
          expect(page).to have_selector('.loading', visible: false)
          expect(page).to have_content('You haven\'t created any personal projects.')
          expect(page).not_to have_selector('.project-row')
        end
      end

      it 'does not show a link to the project list' do
        expect(find('#js-overview .projects-block')).to have_selector('.js-view-all', visible: false)
      end
    end

    describe 'user has a personal project' do
      before do
        create(:project, :private, namespace: user.namespace, creator: user) { |p| p.add_maintainer(user) }
      end

      include_context 'visit overview tab'

      it 'shows one entry in the list of projects' do
        page.within('.projects-block') do
          expect(page).to have_selector('.project-row', count: 1)
        end
      end

      it 'shows a link to the project list' do
        expect(find('#js-overview .projects-block')).to have_selector('.js-view-all', visible: true)
      end

      it 'shows projects in "compact mode"' do
        page.within('#js-overview .projects-block') do
          expect(find('.js-projects-list-holder')).to have_selector('.compact')
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

      it 'shows max. ten entries in the list of projects' do
        page.within('.projects-block') do
          expect(page).to have_selector('.project-row', count: 10)
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

  describe 'bot user' do
    let(:bot_user) { create(:user, user_type: :security_bot) }

    shared_context "visit bot's overview tab" do
      before do
        visit bot_user.username
        page.find('.js-overview-tab a').click
        wait_for_requests
      end
    end

    describe 'feature flag enabled' do
      before do
        stub_feature_flags(security_auto_fix: true)
      end

      include_context "visit bot's overview tab"

      it "activity panel's title is 'Bot activity'" do
        page.within('.activities-block') do
          expect(page).to have_text('Bot activity')
        end
      end

      it 'does not show projects panel' do
        expect(page).not_to have_selector('.projects-block')
      end
    end

    describe 'feature flag disabled' do
      before do
        stub_feature_flags(security_auto_fix: false)
      end

      include_context "visit bot's overview tab"

      it "activity panel's title is not 'Bot activity'" do
        page.within('.activities-block') do
          expect(page).not_to have_text('Bot activity')
        end
      end

      it 'shows projects panel' do
        expect(page).to have_selector('.projects-block')
      end
    end
  end
end
