require 'spec_helper'

feature 'Projects > Wiki > User previews markdown changes', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:wiki_content) do
    <<-HEREDOC
[regular link](regular)
[relative link 1](../relative)
[relative link 2](./relative)
[relative link 3](./e/f/relative)
    HEREDOC
  end

  background do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_path(project.namespace, project)
    click_link 'Wiki'
    WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
  end

  context "while creating a new wiki page" do
    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        click_link 'New Page'
        fill_in :new_wiki_path, with: 'a/b/c/d'
        click_button 'Create Page'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/c/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        click_link 'New Page'
        fill_in :new_wiki_path, with: 'a page/b page/c page/d page'
        click_button 'Create Page'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        click_link 'New Page'
        fill_in :new_wiki_path, with: 'a-page/b-page/c-page/d-page'
        click_button 'Create Page'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end
  end

  context "while editing a wiki page" do
    def create_wiki_page(path)
      click_link 'New Page'
      fill_in :new_wiki_path, with: path
      click_button 'Create Page'
      fill_in :wiki_content, with: 'content'
      click_on "Create page"
    end

    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a/b/c/d'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a/b/c/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a page/b page/c page/d page'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a-page/b-page/c-page/d-page'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_content
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end
  end
end
