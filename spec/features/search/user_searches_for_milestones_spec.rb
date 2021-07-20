# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for milestones', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:milestone1) { create(:milestone, title: 'Foo', project: project) }
  let!(:milestone2) { create(:milestone, title: 'Bar', project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'
  include_examples 'search timeouts', 'milestones'

  it 'finds a milestone' do
    fill_in('dashboard_search', with: milestone1.title)
    find('.btn-search').click
    select_search_scope('Milestones')

    page.within('.results') do
      expect(page).to have_link(milestone1.title)
      expect(page).not_to have_link(milestone2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a milestone' do
      find('[data-testid="project-filter"]').click

      wait_for_requests

      page.within('[data-testid="project-filter"]') do
        click_on(project.name)
      end

      fill_in('dashboard_search', with: milestone1.title)
      find('.btn-search').click
      select_search_scope('Milestones')

      page.within('.results') do
        expect(page).to have_link(milestone1.title)
        expect(page).not_to have_link(milestone2.title)
      end
    end
  end
end
