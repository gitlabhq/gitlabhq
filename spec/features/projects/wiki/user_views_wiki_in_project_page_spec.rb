# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Wiki > User views wiki in project page', feature_category: :wiki do
  before do
    sign_in(project.first_owner)
  end

  context 'when repository is disabled for project' do
    let(:project) do
      create(
        :project,
        :wiki_repo,
        :repository_disabled,
        :merge_requests_disabled,
        :builds_disabled
      )
    end

    context 'when wiki homepage contains a link' do
      shared_examples 'wiki homepage contains a link' do
        it 'displays the correct URL for the link' do
          visit project_path(project)
          expect(page).to have_link(
            'some link',
            href: project_wiki_path(project, 'other-page')
          )
        end
      end

      context 'when using markdown' do
        before do
          create(:wiki_page, wiki: project.wiki, title: 'home', content: '[some link](other-page)')
        end

        it_behaves_like 'wiki homepage contains a link'
      end

      context 'when using asciidoc' do
        before do
          create(
            :wiki_page,
            wiki: project.wiki,
            title: 'home',
            content: 'link:other-page[some link]',
            format: :asciidoc
          )
        end

        it_behaves_like 'wiki homepage contains a link'
      end
    end
  end
end
