# frozen_string_literal: true

require "spec_helper"

describe "User creates wiki page" do
  include CapybaraHelpers
  include WikiHelpers

  set(:user) { create(:user) }

  let(:project) { create(:project) }
  let(:wiki) { ProjectWiki.new(project, user) }
  let(:new_page) { WikiPage.new(wiki) }
  let(:message_field) { form_field_name(new_page, :message) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  def start_writing(page_path)
    click_link("New page")
    fill_in(:wiki_page_title, with: page_path)
  end

  def create_page(attrs = {})
    page.within(".wiki-form") do
      attrs.each do |k, v|
        fill_in("wiki_page_#{k}".to_sym, with: v)
      end
    end
    click_on("Create page")
  end

  shared_examples 'updates commit message' do
    describe 'commit message', :js do
      it "has `Create home` as a commit message" do
        wait_for_requests

        expect(page).to have_field(message_field, with: "Create home")
      end
    end
  end

  context "when wiki is empty" do
    before do
      visit(project_wikis_path(project))

      click_link "Create your first page"
      find('.wiki-form')
    end

    context "in a user namespace" do
      let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
      let(:wiki_page_content) { '' }

      it "shows validation error message" do
        create_page

        expect(page)
          .to have_content("The form contains the following error:")
          .and have_content("Content can't be blank")
          .and have_css('.wiki-form')
          .and have_css('.qa-create-page-button')
      end

      it 'offers to create pages that do not yet exist' do
        create_page(content: "[link test](test)")

        expect(page)
          .to have_content("Home")
          .and have_content("link test")

        click_link("link test")

        expect(page).to have_content("Create New Page")
      end

      it "has a link to the parent directory in the pages sidebar" do
        wiki_full_path = "one/two/three-test"
        create_page(title: wiki_full_path, content: 'wiki content')

        wiki_page = wiki.find_page(wiki_full_path)
        expect(wiki_page).to be_present
        dir = wiki.find_dir(wiki_page.directory)
        expect(dir).to be_present

        expect(current_path).to include(wiki_full_path)

        expect(page).to have_link(dir.slug, href: project_wiki_dir_path(project, dir))
      end

      it "shows non-escaped link in the pages list", :quarantine do
        fill_in(:wiki_title, with: "one/two/three-test")

        page.within(".wiki-form") do
          fill_in(:wiki_content, with: "wiki content")

          click_on("Create page")
        end

        expect(current_path).to include("one/two/three-test")
        expect(page).to have_xpath("//a[@href='/#{project.full_path}/wikis/one/two/three-test']")
      end

      it_behaves_like 'updates commit message'

      it "creates a page from the home page" do
        page_content = <<~WIKI_CONTENT
          [test](test)
          [GitLab API doc](api)
          [Rake tasks](raketasks)
          # Wiki header
        WIKI_CONTENT

        create_page(content: page_content, message: "Adding links to wiki")

        expect(current_path).to eq(project_wiki_path(project, "home"))
        expect(page).to have_content("test GitLab API doc Rake tasks Wiki header")
                   .and have_content("Home")
                   .and have_content("Last edited by #{user.name}")
                   .and have_header_with_correct_id_and_link(1, "Wiki header", "wiki-header")

        click_link("test")

        expect(current_path).to eq(project_wiki_path(project, "test"))

        page.within(:css, ".nav-text") do
          expect(page).to have_content("Create New Page")
        end

        click_link("Home")

        expect(current_path).to eq(project_wiki_path(project, "home"))

        click_link("GitLab API")

        expect(current_path).to eq(project_wiki_path(project, "api"))

        page.within(:css, ".nav-text") do
          expect(page).to have_content("Create")
        end

        click_link("Home")

        expect(current_path).to eq(project_wiki_path(project, "home"))

        click_link("Rake tasks")

        expect(current_path).to eq(project_wiki_path(project, "raketasks"))

        page.within(:css, ".nav-text") do
          expect(page).to have_content("Create")
        end
      end

      it "creates ASCIIdoc wiki with LaTeX blocks", :js do
        stub_application_setting(plantuml_url: "http://localhost", plantuml_enabled: true)

        ascii_content = <<~MD
          :stem: latexmath

          [stem]
          ++++
          \\sqrt{4} = 2
          ++++

          another part

          [latexmath]
          ++++
          \\beta_x \\gamma
          ++++

          stem:[2+2] is 4
        MD

        find("#wiki_page_format option[value=asciidoc]").select_option

        create_page(content: ascii_content)

        page.within ".md" do
          expect(page).to have_selector(".katex", count: 3).and have_content("2+2 is 4")
        end
      end

      it_behaves_like 'wiki file attachments'
    end

    context "in a group namespace" do
      let(:project) { create(:project, :wiki_repo, namespace: create(:group, :public)) }

      it_behaves_like 'updates commit message'

      it "creates a page from the home page" do
        create_page(content: "My awesome wiki!")

        expect(page).to have_content("Home")
                   .and have_content("Last edited by #{user.name}")
                   .and have_content("My awesome wiki!")
      end
    end
  end

  context "when wiki is not empty", :js do
    before do
      create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: 'Home page' })

      visit(project_wikis_path(project))
    end

    shared_examples 'creates page by slug' do |slug, unslug|
      it "creates #{slug}" do
        start_writing(slug)

        # Commit message field should have correct value.
        expect(page).to have_field(message_field, with: "Create #{unslug}")

        create_page(content: "My awesome wiki!")

        expect(page).to have_content(unslug)
                   .and have_content("Last edited by #{user.name}")
                   .and have_content("My awesome wiki!")
      end
    end

    context "in a user namespace" do
      let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }

      context "via the `new wiki page` page" do
        include_examples 'creates page by slug', 'foo', 'foo'
        include_examples 'creates page by slug', 'Spaces in the name', 'Spaces in the name'
        include_examples 'creates page by slug', 'Hyphens-in-the-name', 'Hyphens in the name'
      end

      it "shows the emoji autocompletion dropdown" do
        start_writing('text-autocomplete')

        page.within(".wiki-form") do
          find("#wiki_page_content").native.send_keys("")

          fill_in(:wiki_page_content, with: ":")
        end

        expect(page).to have_selector(".atwho-view")
      end
    end

    context "in a group namespace" do
      let(:project) { create(:project, :wiki_repo, namespace: create(:group, :public)) }

      context "via the `new wiki page` page" do
        include_examples 'creates page by slug', 'foo', 'foo'
        include_examples 'creates page by slug', 'Spaces in the name', 'Spaces in the name'
        include_examples 'creates page by slug', 'Hyphens-in-the-name', 'Hyphens in the name'
      end
    end
  end

  describe 'sidebar feature' do
    context 'when there are some existing pages' do
      before do
        create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: 'home' })
        create(:wiki_page, wiki: wiki, attrs: { title: 'another', content: 'another' })
      end

      it 'renders a default sidebar when there is no customized sidebar' do
        visit(project_wikis_path(project))

        expect(page).to have_content('another')
        expect(page).to have_content('More Pages')
      end

      context 'when there is a customized sidebar' do
        before do
          create(:wiki_page, wiki: wiki, attrs: { title: '_sidebar', content: 'My customized sidebar' })
        end

        it 'renders my customized sidebar instead of the default one' do
          visit(project_wikis_path(project))

          expect(page).to have_content('My customized sidebar')
          expect(page).to have_content('More Pages')
          expect(page).not_to have_content('Another')
        end
      end
    end
  end
end
