require 'spec_helper'

feature 'Projects > Wiki > User previews markdown changes', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  # sample wiki contents for testing
  wiki_supported_formats = {
    'Markdown' => IO.read(Rails.root.join("spec", "fixtures", "sample.md")),
    'AsciiDoc' => IO.read(Rails.root.join("spec", "fixtures", "sample.adoc")),
    'RDoc' => IO.read(Rails.root.join("spec", "fixtures", "sample.rdoc"))
  }

  # wiki page path types
  wiki_slug_types = {
    'no spaces or hyphens' => {
      path: 'a/b/c/d',
      expectations: [:expect_norm_relative_links]
    },
    'spaces' => {
      path: 'a page/b page/c page/d page',
      expectations: [:expect_hyphened_relative_links]
    },
    'hyphens' => {
      path: 'a-page/b-page/c-page/d-page',
      expectations: [:expect_hyphened_relative_links]
    }
  }

  background do
    project.add_master(user)

    sign_in(user)

    visit project_path(project)
    find('.shortcuts-wiki').click
  end

  context "while creating a new wiki page" do
    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        find('.add-new-wiki').click
        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'a/b/c/d'
          click_button 'Create page'
        end

        page.within '.wiki-form' do
          fill_in :wiki_content, with: wiki_supported_formats['Markdown']
          click_on "Preview"
        end

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/c/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        click_link 'New page'
        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'a page/b page/c page/d page'
          click_button 'Create page'
        end

        page.within '.wiki-form' do
          fill_in :wiki_content, with: wiki_supported_formats['Markdown']
          click_on "Preview"
        end

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        click_link 'New page'
        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'a-page/b-page/c-page/d-page'
          click_button 'Create page'
        end

        page.within '.wiki-form' do
          fill_in :wiki_content, with: wiki_supported_formats['Markdown']
          click_on "Preview"
        end

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end
  end

  context "while editing a wiki page" do
    context "when there are no spaces or hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a/b/c/d'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_supported_formats['Markdown']
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/c/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a/b/c/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are spaces in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a page/b page/c page/d page'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_supported_formats['Markdown']
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end

    context "when there are hyphens in the page name" do
      it "rewrites relative links as expected" do
        create_wiki_page 'a-page/b-page/c-page/d-page'
        click_link 'Edit'

        fill_in :wiki_content, with: wiki_supported_formats['Markdown']
        click_on "Preview"

        expect(page).to have_content("regular link")

        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/regular\">regular link</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/relative\">relative link 1</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/relative\">relative link 2</a>")
        expect(page.html).to include("<a href=\"/#{project.full_path}/wikis/a-page/b-page/c-page/e/f/relative\">relative link 3</a>")
      end
    end
  end

  shared_examples 'using wiki' do |edit_wiki|
    # tests all supported formats
    wiki_supported_formats.each do |w_format, w_content|
      context "user selects #{w_format}" do
        wiki_slug_types.each do |slug_type, slug_data|
          context "when there are #{slug_type} in the page name" do
            it 'renders html as expected' do
              create_wiki_page(slug_data[:path], w_format, w_content, edit_wiki)
              click_on 'Preview'

              expect_common

              slug_data[:expectations].each do |expectation|
                method(expectation).call
              end
            end
          end
        end
      end
    end
  end

  context 'when creating a new wiki page' do
    it_behaves_like 'using wiki', false
  end

  context 'when editing a wiki page' do
    it_behaves_like 'using wiki', true
  end

  def create_wiki_page(path, wiki_format = 'Markdown', content = 'content', edit = false)
    find('.add-new-wiki').click

    page.within '#modal-new-wiki' do
      fill_in :new_wiki_path, with: path
      click_button 'Create page'
    end

    page.within '.wiki-form' do
      if edit
        fill_in :wiki_content, with: 'content'
      else
        fill_in :wiki_content, with: content
      end

      select(wiki_format, from: 'wiki_format')

      click_on "Create page"
    end

    if edit
      find('[name=commit]').click
      click_link 'Edit'
      fill_in :wiki_content, with: content
      select(wiki_format, from: 'wiki_format')
    end
  end
end
