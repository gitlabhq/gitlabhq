# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Wiki > User views wiki in project page' do
  before do
    sign_in(project.owner)
  end

  context 'when repository is disabled for project' do
    let_it_be(:project) do
      create(:project,
             :wiki_repo,
             :repository_disabled,
             :merge_requests_disabled,
             :builds_disabled)
    end

    context 'when wiki homepage contains a link' do
      before do
        create(:wiki_page, wiki: project.wiki, title: 'home', content: '[some link](other-page)')
      end

      it 'displays the correct URL for the link' do
        visit project_path(project)
        expect(page).to have_link(
          'some link',
          href: project_wiki_path(project, 'other-page')
        )
      end
    end
  end
end
