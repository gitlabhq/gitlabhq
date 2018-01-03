require 'spec_helper'

feature 'Projects > Wiki > User previews changes', feature: true, js: true do
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
    },
  }

  def init_wiki_page(path, wiki_format, content, edit = false)
    click_link 'New Page'

    fill_in :new_wiki_path, with: path
    click_button 'Create Page'

    if edit
      fill_in :wiki_content, with: 'content'
    else
      fill_in :wiki_content, with: content
    end

    select(wiki_format, from: 'wiki_format')

    if edit
      find('[name=commit]').click
      click_link 'Edit'
      fill_in :wiki_content, with: content
      select(wiki_format, from: 'wiki_format')
    end
    click_on 'Preview'
  end

  def expect_common
    expect(page).to have_selector('h1', text: 'My Article')
    expect(page).to have_selector('h2', text: 'Software')
    expect(page).to have_link('Wikipedia', href: 'http://wikipedia.org')
    expect(page).to have_link('regular link', href: "/#{project.path_with_namespace}/wikis/regular")
  end

  def expect_hyphened_relative_links
    expect(page).to have_link('relative link 1', href: "/#{project.path_with_namespace}/wikis/a-page/b-page/relative")
    expect(page).to have_link('relative link 2', href: "/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/relative")
    expect(page).to have_link('relative link 3', href: "/#{project.path_with_namespace}/wikis/a-page/b-page/c-page/e/f/relative")
  end

  def expect_norm_relative_links
    expect(page).to have_link('relative link 1', href: "/#{project.path_with_namespace}/wikis/a/b/relative")
    expect(page).to have_link('relative link 2', href: "/#{project.path_with_namespace}/wikis/a/b/c/relative")
    expect(page).to have_link('relative link 3', href: "/#{project.path_with_namespace}/wikis/a/b/c/e/f/relative")
  end

  background do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_path(project.namespace, project)
    click_link 'Wiki'
    WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
  end

  shared_context 'using wiki' do |edit_wiki|
    # tests all supported formats
    wiki_supported_formats.each do |w_format, w_content|
      context "user selects #{w_format}" do
        wiki_slug_types.each do |slug_type, slug_data|
          context "when there are #{slug_type} in the page name" do
            it 'renders html as expected' do
              init_wiki_page(slug_data[:path], w_format, w_content, edit_wiki)
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
    include_context 'using wiki', false
  end

  context 'when editing a wiki page' do
    include_context 'using wiki', true
  end
end
