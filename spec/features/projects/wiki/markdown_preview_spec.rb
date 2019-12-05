# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Wiki > User previews markdown changes', :js do
  set(:user) { create(:user) }
  let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki, attrs: { title: 'home', content: '[some link](other-page)' }) }
  let(:wiki_content) do
    <<-HEREDOC
[regular link](regular)
[relative link 1](../relative)
[relative link 2](./relative)
[relative link 3](./e/f/relative)
[spaced link](title with spaces)
    HEREDOC
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context "while creating a new wiki page" do
    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a/b/c/d', content: wiki_content)

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/c/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a page/b page/c page/d page', content: wiki_content)

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a-page/b-page/c-page/d-page', content: wiki_content)

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end
  end

  context "while editing a wiki page" do
    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a/b/c/d')
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a/b/c/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a page/b page/c page/d page')
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page('a-page/b-page/c-page/d-page')
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/-/wikis/title%20with%20spaces\">spaced link</a>")
      end
    end

    context 'when rendering the preview' do
      it 'renders content with CommonMark' do
        create_wiki_page('a-page/b-page/c-page/common-mark')
        click_link 'Edit'

        fill_in :wiki_content, with: "1. one\n  - sublist\n"
        click_on "Preview"

        # the above generates two separate lists (not embedded) in CommonMark
        expect(page).to have_content("sublist")
        expect(page).not_to have_xpath("//ol//li//ul")
      end
    end
  end

  it "does not linkify double brackets inside code blocks as expected" do
    wiki_content = <<-HEREDOC
      `[[do_not_linkify]]`
      ```
      [[also_do_not_linkify]]
      ```
    HEREDOC

    create_wiki_page('linkify_test', wiki_content)

    expect(page).to have_content("do_not_linkify")

    expect(page.html).to include('[[do_not_linkify]]')
    expect(page.html).to include('[[also_do_not_linkify]]')
  end

  private

  def create_wiki_page(path, content = 'content')
    visit project_wiki_path(project, wiki_page)

    click_link 'New page'

    fill_in :wiki_title, with: path
    fill_in :wiki_content, with: content

    click_button 'Create page'
  end
end
