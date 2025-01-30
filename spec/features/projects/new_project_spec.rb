# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project', :js, feature_category: :groups_and_projects do
  include ListboxHelpers

  before do
    stub_application_setting(import_sources: Gitlab::ImportSources.values)
    stub_feature_flags(new_project_creation_form: false)
  end

  shared_examples 'shows correct navigation' do
    context 'for a new top-level project' do
      it 'shows the "Your work" navigation' do
        visit new_project_path
        expect(page).to have_selector(".super-sidebar", text: "Your work")
      end
    end

    context 'for a new group project' do
      let_it_be(:parent_group) { create(:group) }

      before do
        parent_group.add_owner(user)
      end

      it 'shows the group sidebar of the parent group' do
        visit new_project_path(namespace_id: parent_group.id)
        expect(page).to have_selector(".super-sidebar", text: parent_group.name)
      end
    end
  end

  context 'as a user' do
    let_it_be(:user) { create(:user) }

    before do
      stub_feature_flags(new_project_creation_form: false)
      sign_in(user)
    end

    it_behaves_like 'shows correct navigation'

    it 'shows the project description field when it should' do
      description_label = 'Project description (optional)'

      visit new_project_path
      click_link 'Create blank project'

      page.within('#blank-project-pane') do
        expect(page).not_to have_content(description_label)
      end

      visit new_project_path
      click_link 'Import project'

      page.within('#import-project-pane') do
        click_button 'Repository by URL'

        expect(page).to have_content(description_label)
      end

      visit new_project_path
      click_link 'Create from template'

      page.within('#create-from-template-pane') do
        find("[data-testid='use_template_#{Gitlab::ProjectTemplate.localized_templates_table.first.name}']").click

        expect(page).to have_content(description_label)
      end
    end

    it 'disables the radio button for visibility levels "Private" and "Internal"' do
      stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::PUBLIC)
      stub_application_setting(
        restricted_visibility_levels: [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL]
      )

      visit new_project_path
      click_link 'Create blank project'

      expect(page).to have_field("Private",  checked: false, disabled: true)
      expect(page).to have_field("Internal", checked: false, disabled: true)
      expect(page).to have_field("Public",   checked: true,  disabled: false)
    end

    it 'disables all radio button for visibility levels' do
      stub_application_setting(restricted_visibility_levels: Gitlab::VisibilityLevel.values)

      visit new_project_path
      click_link 'Create blank project'

      expect(page).to have_field("Private",  checked: true, disabled: true)
      expect(page).to have_field("Internal", checked: false, disabled: true)
      expect(page).to have_field("Public",   checked: false, disabled: true)
    end
  end

  context 'as an admin' do
    let(:user) { create(:admin) }

    it_behaves_like 'shows correct navigation'

    shared_examples '"New project" page' do
      before do
        stub_feature_flags(new_project_creation_form: false)
        sign_in(user)
      end

      it 'shows "New project" page', :js do
        visit new_project_path
        click_link 'Create blank project'

        expect(page).to have_content('Project name')
        expect(page).to have_content('Project URL')
        expect(page).to have_content('Project slug')

        click_link('New project')
        click_link 'Import project'

        expect(page).to have_link('GitHub')
        expect(page).to have_link('Bitbucket')
        expect(page).to have_button('Repository by URL')
        expect(page).to have_link('GitLab export')
      end
    end

    include_examples '"New project" page'

    shared_examples 'renders importer link' do |params|
      context 'with user namespace' do
        before do
          visit new_project_path
          click_link 'Import project'
        end

        it "renders link to #{params[:name]} importer" do
          expect(page).to have_link(href: Rails.application.routes.url_helpers.send(params[:route]))
        end
      end

      context 'with group namespace' do
        let(:group) { create(:group, :private) }

        before do
          group.add_owner(user)
          visit new_project_path(namespace_id: group.id)
          click_link 'Import project'
        end

        it "renders link to #{params[:name]} importer including namespace id" do
          expect(page).to have_link(href: Rails.application.routes.url_helpers.send(params[:route], namespace_id: group.id))
        end
      end
    end

    describe 'importer links' do
      shared_examples 'link to importers' do
        let(:importer_routes) do
          {
            'github': :new_import_github_path,
            'bitbucket': :status_import_bitbucket_path,
            'bitbucket server': :status_import_bitbucket_server_path,
            'fogbugz': :new_import_fogbugz_path,
            'gitea': :new_import_gitea_path,
            'manifest': :new_import_manifest_path
          }
        end

        it 'renders links to several importers', :aggregate_failures do
          importer_routes.each_value do |route|
            expect(page).to have_link(href: Rails.application.routes.url_helpers.send(route, link_params))
          end
        end
      end

      context 'with user namespace' do
        let(:link_params) { {} }

        before do
          visit new_project_path
          click_link 'Import project'
        end

        include_examples 'link to importers'
      end

      context 'with group namespace' do
        let(:group) { create(:group, :private) }
        let(:link_params) { { namespace_id: group.id } }

        before do
          group.add_owner(user)
          visit new_project_path(namespace_id: group.id)
          click_link 'Import project'
        end

        include_examples 'link to importers'
      end
    end

    context 'Visibility level selector', :js do
      Gitlab::VisibilityLevel.options.each do |key, level|
        it "sets selector to #{key}" do
          stub_application_setting(default_project_visibility: level)

          visit new_project_path
          click_link 'Create blank project'
          page.within('#blank-project-pane') do
            expect(page).to have_field(key, checked: true)
          end
        end

        it "saves visibility level #{level} on validation error" do
          visit new_project_path
          click_link 'Create blank project'

          choose(key)
          click_button('Create project')
          page.within('#blank-project-pane') do
            expect(page).to have_field(key, checked: true)
          end
        end
      end

      context 'when group visibility is private but default is internal' do
        let_it_be(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'has private selected' do
            visit new_project_path(namespace_id: group.id)
            click_link 'Create blank project'

            page.within('#blank-project-pane') do
              expect(page).to have_field('Private', checked: true)
            end
          end
        end

        context 'when admin mode is disabled' do
          it 'is not allowed' do
            visit new_project_path(namespace_id: group.id)

            expect(page).to have_content('Page not found')
          end
        end
      end

      context 'when group visibility is public but user requests private' do
        let_it_be(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

        before do
          stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'has private selected' do
            visit new_project_path(namespace_id: group.id, project: { visibility_level: Gitlab::VisibilityLevel::PRIVATE })
            click_link 'Create blank project'

            page.within('#blank-project-pane') do
              expect(page).to have_field('Private', checked: true)
            end
          end
        end

        context 'when admin mode is disabled' do
          it 'is not allowed' do
            visit new_project_path(namespace_id: group.id, project: { visibility_level: Gitlab::VisibilityLevel::PRIVATE })

            expect(page).to have_content('Page not found')
          end
        end
      end
    end

    context 'Readme selector' do
      it 'shows the initialize with Readme checkbox on "Blank project" tab' do
        visit new_project_path
        click_link 'Create blank project'

        expect(page).to have_css('input#project_initialize_with_readme')
        expect(page).to have_content('Initialize repository with a README')
      end

      it 'does not show the initialize with Readme checkbox on "Create from template" tab' do
        visit new_project_path
        click_link 'Create from template'
        first('.choose-template').click

        page.within '.project-fields-form' do
          expect(page).not_to have_css('input#project_initialize_with_readme')
          expect(page).not_to have_content('Initialize repository with a README')
        end
      end

      it 'does not show the initialize with Readme checkbox on "Import project" tab' do
        visit new_project_path
        click_link 'Import project'
        click_button 'Repository by URL'

        page.within '#import-project-pane' do
          expect(page).not_to have_css('input#project_initialize_with_readme')
          expect(page).not_to have_content('Initialize repository with a README')
        end
      end
    end

    context 'Namespace selector' do
      context 'with user namespace' do
        before do
          visit new_project_path
          click_link 'Create blank project'
        end

        it 'does not select the user namespace' do
          click_on 'Pick a group or namespace'
          expect_listbox_item(user.username)
        end
      end

      context 'with group namespace' do
        let(:group) { create(:group, :private) }

        before do
          group.add_owner(user)
          visit new_project_path(namespace_id: group.id)
          click_link 'Create blank project'
        end

        it 'selects the group namespace' do
          expect(page).to have_button group.name
        end
      end

      context 'with subgroup namespace' do
        let(:group) { create(:group) }
        let(:subgroup) { create(:group, parent: group) }

        before do
          group.add_maintainer(user)
          visit new_project_path(namespace_id: subgroup.id)
          click_link 'Create blank project'
        end

        it 'selects the group namespace' do
          expect(page).to have_button subgroup.full_path
        end
      end

      context 'when changing namespaces dynamically', :js do
        let(:public_group) { create(:group, :public) }
        let(:internal_group) { create(:group, :internal) }
        let(:private_group) { create(:group, :private) }

        before do
          public_group.add_owner(user)
          internal_group.add_owner(user)
          private_group.add_owner(user)
          visit new_project_path(namespace_id: public_group.id)
          click_link 'Create blank project'
        end

        it 'enables the correct visibility options' do
          click_button public_group.full_path
          select_listbox_item user.username

          expect(page).to have_field("Private", disabled: false)
          expect(page).to have_field("Internal", disabled: false)
          expect(page).to have_field("Public", disabled: false)

          click_button user.username
          select_listbox_item public_group.full_path

          expect(page).to have_field("Private", disabled: false)
          expect(page).to have_field("Internal", disabled: false)
          expect(page).to have_field("Public", disabled: false)

          click_button public_group.full_path
          select_listbox_item internal_group.full_path

          expect(page).to have_field("Private", disabled: false)
          expect(page).to have_field("Internal", disabled: false)
          expect(page).to have_field("Public", disabled: true)

          click_button internal_group.full_path
          select_listbox_item private_group.full_path

          expect(page).to have_field("Private", disabled: false)
          expect(page).to have_field("Internal", disabled: true)
          expect(page).to have_field("Public", disabled: true)
        end
      end
    end

    context 'Import project options without any sources', :js do
      before do
        stub_application_setting(import_sources: [])

        visit new_project_path
        click_link 'Import project'
      end

      it 'displays the no import options message' do
        expect(page).to have_text s_('ProjectsNew|No import options available')
        expect(page).to have_text s_('ProjectsNew|Contact an administrator to enable options for importing your project.')
      end
    end

    context 'Import project options', :js do
      before do
        visit new_project_path
        click_link 'Import project'
      end

      context 'from git repository url, "Repository by URL"' do
        before do
          first('.js-import-git-toggle-button').click
        end

        it 'does not autocomplete sensitive git repo URL' do
          autocomplete = find('#project_import_url')['autocomplete']

          expect(autocomplete).to eq('off')
        end

        it 'shows import instructions' do
          git_import_instructions = first('.js-toggle-content')

          expect(git_import_instructions).to be_visible
          expect(git_import_instructions).to have_content 'Git repository URL'
        end

        it 'reports error if repo URL is not a valid Git repository' do
          stub_request(:get, "http://foo/bar/info/refs?service=git-upload-pack").to_return(status: 200, body: "not-a-git-repo")

          fill_in 'project_import_url', with: 'http://foo/bar'
          # simulate blur event
          find('body').click

          wait_for_requests

          expect(page).to have_text('There is not a valid Git repository at this URL')
        end

        it 'reports error if repo URL is not a valid Git repository and submit button is clicked immediately' do
          stub_request(:get, "http://foo/bar/info/refs?service=git-upload-pack").to_return(status: 200, body: "not-a-git-repo")

          fill_in 'project_import_url', with: 'http://foo/bar'
          click_on 'Create project'

          wait_for_requests

          expect(page).to have_text('There is not a valid Git repository at this URL')
        end

        it 'keeps "Import project" tab open after form validation error' do
          collision_project = create(:project, name: 'test-name-collision', namespace: user.namespace)
          stub_request(:get, "http://foo/bar/info/refs?service=git-upload-pack").to_return(
            { status: 200,
              body: '001e# service=git-upload-pack',
              headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' } })

          fill_in 'project_import_url', with: 'http://foo/bar'
          fill_in 'project_name', with: collision_project.name

          click_on 'Create project'

          expect(page).to have_content(
            s_('ProjectsNew|Pick a group or namespace where you want to create this project.')
          )

          click_on 'Pick a group or namespace'
          select_listbox_item user.username
          click_on 'Create project'

          expect(page).to have_css('#import-project-pane.active')
          expect(page).not_to have_css('.toggle-import-form.hide')
        end
      end

      context 'when import is initiated from project page' do
        before do
          project_without_repo = create(:project, name: 'project-without-repo', namespace: user.namespace)
          visit project_path(project_without_repo)
          click_on 'Import repository'
        end

        it 'reports error when invalid url is provided' do
          stub_request(:get, "http://foo/bar/info/refs?service=git-upload-pack").to_return(status: 200, body: "not-a-git-repo")

          fill_in 'project_import_url', with: 'http://foo/bar'

          click_on 'Start import'
          wait_for_requests

          expect(page).to have_text('There is not a valid Git repository at this URL')
        end

        it 'initiates import when valid repo url is provided' do
          stub_request(:get, "http://foo/bar/info/refs?service=git-upload-pack").to_return(
            { status: 200,
              body: '001e# service=git-upload-pack',
              headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' } })

          fill_in 'project_import_url', with: 'http://foo/bar'

          click_on 'Start import'
          wait_for_requests

          expect(page).to have_text('Import in progress')
        end
      end

      context 'from GitHub' do
        before do
          first('.js-import-github').click
        end

        it 'shows import instructions' do
          expect(page).to have_content('Authenticate with GitHub')
          expect(page).to have_current_path new_import_github_path, ignore_query: true
        end
      end

      context 'from manifest file' do
        before do
          first('.import_manifest').click
        end

        it 'shows import instructions' do
          expect(page).to have_content('Manifest file import')
          expect(page).to have_current_path new_import_manifest_path, ignore_query: true
        end
      end
    end

    context 'Namespace selector' do
      context 'with group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
        let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

        before do
          group.add_developer(user)
          visit new_project_path(namespace_id: group.id)
          click_link 'Create blank project'
        end

        it 'selects the group namespace' do
          expect(page).to have_button group.full_path
        end
      end
    end
  end

  shared_examples 'has instructions to enable OAuth' do
    context 'when OAuth is not configured' do
      before do
        stub_feature_flags(new_project_creation_form: false)
        sign_in(user)

        allow(Gitlab::Auth::OAuth::Provider).to receive(:enabled?).and_call_original
        allow(Gitlab::Auth::OAuth::Provider)
          .to receive(:enabled?).with(provider)
          .and_return(false)

        visit new_project_path
        click_link 'Import project'
        click_link target_link
      end

      it 'shows import instructions' do
        expect(find('.modal-body')).to have_content(oauth_config_instructions)
      end
    end
  end

  context 'from Bitbucket', :js do
    let(:target_link) { 'Bitbucket Cloud' }
    let(:provider) { :bitbucket }

    context 'as a user' do
      let(:user) { create(:user) }
      let(:oauth_config_instructions) { 'To enable importing projects from Bitbucket, ask your GitLab administrator to configure OAuth integration' }

      it_behaves_like 'has instructions to enable OAuth'
    end

    context 'as an admin', :do_not_mock_admin_mode_setting do
      let(:user) { create(:admin) }
      let(:oauth_config_instructions) { 'To enable importing projects from Bitbucket, as administrator you need to configure OAuth integration' }

      it_behaves_like 'has instructions to enable OAuth'
    end
  end
end
