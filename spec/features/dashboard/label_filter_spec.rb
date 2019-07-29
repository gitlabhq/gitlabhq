# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard > label filter', :js do
  include FilteredSearchHelpers

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find("#js-dropdown-label .filter-dropdown") }

  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:project2) { create(:project, name: 'test2', path: 'test2', namespace: user.namespace) }
  let(:label) { create(:label, title: 'bug', color: '#ff0000') }
  let(:label2) { create(:label, title: 'bug') }

  before do
    project.labels << label
    project2.labels << label2

    sign_in(user)
    visit issues_dashboard_path

    init_label_search
  end

  context 'duplicate labels' do
    it 'removes duplicate labels' do
      filtered_search.send_keys('bu')

      expect(filter_dropdown).to have_selector('.filter-dropdown-item', text: 'bug', count: 1)
    end
  end
end
