# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Granular personal access tokens > tokens table',
  :with_current_organization, :js, feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers

  let_it_be(:user) { create(:user, :with_namespace) }

  let_it_be(:active_token) do
    create(:granular_pat,
      user: user,
      name: 'Active PAT',
      description: 'Active PAT description',
      expires_at: 1.month.from_now,
      last_used_at: 1.day.ago
    )
  end

  let_it_be(:expiring_token) do
    create(:granular_pat,
      user: user,
      name: 'Expiring soon token',
      description: nil,
      expires_at: 5.days.from_now,
      last_used_at: nil
    )
  end

  let_it_be(:revoked_token) do
    create(:granular_pat, :revoked, user: user, name: 'Revoked PAT')
  end

  let_it_be(:expired_token) do
    create(:granular_pat, :expired, user: user, name: 'Expired PAT')
  end

  let_it_be(:legacy_active_token) do
    create(:personal_access_token,
      user: user,
      name: 'Legacy active token',
      expires_at: 20.days.from_now
    )
  end

  before do
    stub_feature_flags(granular_personal_access_tokens: true)
    sign_in(user)
    visit user_settings_personal_access_tokens_path
  end

  it 'lists every active token (granular and legacy) by name' do
    within('table') do
      expect(page).to have_text(active_token.name)
      expect(page).to have_text(expiring_token.name)
      expect(page).to have_text(legacy_active_token.name)

      expect(page).not_to have_text(revoked_token.name)
      expect(page).not_to have_text(expired_token.name)
    end
  end

  it 'renders the description column' do
    row = find('tr', text: active_token.name)

    expect(row).to have_text(active_token.description)
  end

  it 'renders the description column with a placeholder when description is blank' do
    row = find('tr', text: expiring_token.name)

    expect(row).to have_text('No description provided.')
  end

  it 'shows the expiry and last-used fields for each row' do
    row = find('tr', text: active_token.name)

    within(row) do
      within_testid('token-expiry') do
        expect(page).to have_text('Expires:')
      end

      within_testid('token-last-used') do
        expect(page).to have_text('Last used:')
      end
    end
  end

  it 'renders `Never` for tokens that have not been used yet' do
    row = find('tr', text: expiring_token.name)

    within(row) do
      within_testid('token-last-used') do
        expect(page).to have_text('Last used: Never')
      end
    end
  end

  it 'renders tokens expiring in the next two weeks with an `Expiring soon` badge' do
    expect(find('tr', text: expiring_token.name)).to have_text('Expiring soon')
  end

  it 'renders the empty state when no tokens match the current filter' do
    find_by_testid('filtered-search-term-input').set('no-such-token-xyz')
    find_by_testid('filtered-search-term-input').send_keys(:enter)

    expect(page).to have_text('No access tokens')
  end

  describe 'statistics cards' do
    it 'shows the four statistics cards' do
      titles = page.all('[data-testid="stat-title"]').map(&:text)

      expect(titles).to include(
        'Active tokens',
        'Tokens expiring in 2 weeks',
        'Revoked tokens',
        'Expired tokens'
      )

      expect(stat_card('Active tokens')).to have_selector('[data-testid="stat-value"]', text: '3')
      expect(stat_card('Tokens expiring in 2 weeks')).to have_selector('[data-testid="stat-value"]', text: '1')
      expect(stat_card('Revoked tokens')).to have_selector('[data-testid="stat-value"]', text: '1')
      expect(stat_card('Expired tokens')).to have_selector('[data-testid="stat-value"]', text: '1')
    end

    it 'applies the revoked filter' do
      within(stat_card('Revoked tokens')) { click_button 'Filter list' }

      expect(page).to have_text(revoked_token.name)
      expect(page).not_to have_text(active_token.name)
    end

    it 'applies the expired filter' do
      within(stat_card('Expired tokens')) { click_button 'Filter list' }

      expect(page).to have_text(expired_token.name)
      expect(page).not_to have_text(active_token.name)
    end
  end

  describe 'filtering' do
    it 'shows revoked tokens when the `revoked=true` filter is applied' do
      clear_filter_chips

      find_by_testid('filtered-search-term-input').click
      click_button 'Revoked'
      click_button 'Yes'
      find('.gl-search-box-by-click-search-button').click

      expect(page).to have_text(revoked_token.name)
      expect(page).not_to have_text(active_token.name)
    end

    it 'shows inactive tokens when the `state=inactive` filter is applied' do
      clear_filter_chips

      find_by_testid('filtered-search-term-input').click
      click_button 'State'
      click_button 'Inactive'
      find('.gl-search-box-by-click-search-button').click

      expect(page).to have_text(expired_token.name)
      expect(page).to have_text(revoked_token.name)
      expect(page).not_to have_text(active_token.name)
    end

    it 'shows results when a free-text search term is added' do
      find_by_testid('filtered-search-term-input').set(expiring_token.name)
      find_by_testid('filtered-search-term-input').send_keys(:enter)

      expect(page).to have_text(expiring_token.name)
      expect(page).not_to have_text(active_token.name)
    end

    it 'persists the current filter into the URL query string' do
      clear_filter_chips

      find_by_testid('filtered-search-term-input').click
      click_button 'Revoked'
      click_button 'Yes'
      find('.gl-search-box-by-click-search-button').click

      expect(page).to have_text(revoked_token.name)
      expect(page.current_url).to include('revoked=true')
    end
  end

  context 'when sorting' do
    it 'defaults to sorting by expiration date ascending (soonest first)' do
      expect(page).to have_css('table tbody tr', count: 3)

      expect(visible_token_names).to eq([
        expiring_token.name,
        legacy_active_token.name,
        active_token.name
      ])
    end

    it 'reorders rows alphabetically when sorting by name' do
      within('.gl-sorting') { click_button 'Expiration date' }
      select_listbox_item 'Name'

      expect(page).to have_css('table tbody tr', count: 3)

      expect(visible_token_names).to eq([
        active_token.name,
        expiring_token.name,
        legacy_active_token.name
      ])
    end

    it 'toggles direction when the sort-direction button is clicked' do
      find('.sorting-direction-button').click

      expect(page).to have_css('table tbody tr', count: 3)

      expect(visible_token_names).to eq([
        active_token.name,
        legacy_active_token.name,
        expiring_token.name
      ])
    end
  end

  context 'when paginating' do
    let_it_be(:extra_tokens) do
      create_list(:granular_pat, 10, user: user, expires_at: 120.days.from_now)
    end

    it 'advances to the second page when `Next` is clicked' do
      expect(page).to have_css('table tbody tr', count: 10)
      expect(visible_token_names).to include(active_token.name)

      click_button 'Next'

      expect(page).to have_css('table tbody tr', count: 3)

      expect(visible_token_names).not_to include(active_token.name)
    end

    it 'returns to the previous page when `Previous` is clicked' do
      click_button 'Next'

      expect(page).to have_css('table tbody tr', count: 3)

      expect(visible_token_names).not_to include(active_token.name)

      click_button 'Previous'

      expect(page).to have_css('table tbody tr', count: 10)

      expect(visible_token_names).to include(active_token.name)
    end
  end

  context 'with row actions' do
    it 'opens the drawer when `View details` is selected' do
      open_row_actions(active_token.name)
      click_button 'View details'

      within('#contextual-panel-portal') do
        expect(page).to have_text(active_token.name)
        expect(page).to have_text('Personal access token detail')
      end
    end

    it 'revokes a token through the confirmation modal' do
      open_row_actions(active_token.name)
      click_button 'Revoke'

      within_modal do
        expect(page).to have_text("Revoke the token '#{active_token.name}'?")
        click_button 'Revoke'
      end

      expect(page).to have_text('The token was revoked successfully.')
      expect(page).not_to have_text(active_token.name)
    end

    it 'rotates a token through the confirmation modal' do
      open_row_actions(active_token.name)
      click_button 'Rotate'

      within_modal do
        expect(page).to have_text("Rotate the token '#{active_token.name}'?")
        click_button 'Rotate'
      end

      expect(page).to have_text('Make sure you copy your token - you won\'t be able to access it again.')
    end

    it 'shows the duplicate action only for granular tokens' do
      open_row_actions(active_token.name)
      expect(page).to have_button('Duplicate')

      page.send_keys(:escape)

      open_row_actions(legacy_active_token.name)
      expect(page).not_to have_button('Duplicate')
    end
  end

  def visible_token_names
    page.all('table tbody tr td:first-child').map(&:text)
  end

  def stat_card(title)
    find_by_testid('stat-title', text: title).ancestor('.gl-card')
  end

  def clear_filter_chips
    page.all('.gl-token-close').each(&:click) # rubocop:disable Rails/FindEach -- Capybara collection, not an ActiveRecord relation
    page.execute_script('document.activeElement.blur()')
  end

  def open_row_actions(token_name)
    row = find('tr', text: token_name)
    within(row) { click_button 'Actions' }
  end
end
