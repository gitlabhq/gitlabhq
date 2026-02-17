# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User explores projects', :js, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  include GlFilteredSearchHelpers

  describe 'sidebar and breadcrumbs' do
    where(:explore_projects_vue, :tab, :path) do
      true  | 'Active'       | active_explore_projects_path
      true  | 'Inactive'     | inactive_explore_projects_path
      true  | 'Trending'     | trending_explore_projects_path
      false | 'All'          | explore_projects_path({ archived: 'true' })
      false | 'Most starred' | starred_explore_projects_path
      false | 'Trending'     | trending_explore_projects_path
    end

    with_them do
      context "when visiting tab" do
        before do
          stub_feature_flags(explore_projects_vue: explore_projects_vue, retire_trending_projects: false)

          visit path
        end

        describe "sidebar" do
          it 'shows the "Explore" sidebar' do
            has_testid?('super-sidebar')
            within_testid('super-sidebar') do
              expect(page).to have_css('#super-sidebar-context-header', text: 'Explore')
            end
          end

          it 'shows the "Projects" menu item as active' do
            within_testid('super-sidebar') do
              expect(page).to have_css("[aria-current='page']", text: "Projects")
            end
          end
        end

        describe 'breadcrumbs' do
          it 'has "Explore" as its root breadcrumb' do
            within_testid('breadcrumb-links') do
              expect(find('li:first-of-type')).to have_link('Explore', href: explore_root_path)
            end
          end
        end
      end
    end
  end

  describe 'tabs' do
    it 'renders all expected tabs', :aggregate_failures do
      visit(explore_projects_path)

      expect(page).to have_selector('.gl-tab-nav-item', text: 'Active')
      expect(page).to have_selector('.gl-tab-nav-item', text: 'Inactive')
    end

    context 'when `explore_projects_vue` flag is disabled' do
      it 'renders all expected tabs', :aggregate_failures do
        stub_feature_flags(explore_projects_vue: false)

        visit(explore_projects_path)

        expect(page).to have_selector('.gl-tab-nav-item', text: 'All')
        expect(page).to have_selector('.gl-tab-nav-item', text: 'Most starred')
      end
    end

    context 'when `retire_trending_projects` flag is disabled' do
      it 'renders trending tab' do
        stub_feature_flags(retire_trending_projects: false)

        visit(explore_projects_path)

        expect(page).to have_selector('.gl-tab-nav-item', text: 'Trending')
      end
    end
  end

  describe 'list' do
    context 'when there are no projects' do
      context 'when `explore_projects_vue` flag is disabled' do
        before do
          stub_feature_flags(explore_projects_vue: false)
        end

        where(:path, :message) do
          explore_projects_path          | 'Explore public groups to find projects to contribute to'
          starred_explore_projects_path  | 'Explore public groups to find projects to contribute to'
          trending_explore_projects_path | 'Explore public groups to find projects to contribute to'
        end

        with_them do
          it 'displays the expected empty message' do
            visit path

            expect(page).to have_content(message)
          end
        end
      end
    end

    context 'when there are projects' do
      let_it_be(:archived_project) { create(:project, :archived) }
      let_it_be(:internal_project) { create(:project, :internal) }
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:public_project) { create(:project, :public) }

      before do
        [archived_project, public_project, internal_project].each { |project| create(:note_on_issue, project: project) }

        TrendingProject.refresh!
      end

      context 'when not signed in' do
        context 'when viewing public projects' do
          before do
            visit(explore_projects_path)
          end

          include_examples 'shows public projects'
        end

        context 'when visibility is restricted to public' do
          before do
            stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

            visit(explore_projects_path)
          end

          it 'redirects to login page' do
            expect(page).to have_current_path(new_user_session_path)
          end
        end
      end

      context 'when signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        context 'when viewing public projects' do
          before do
            visit(explore_projects_path)
          end

          include_examples 'shows public and internal projects'
        end

        context 'when viewing trending projects' do
          it 'redirects to active projects page' do
            visit trending_explore_projects_path

            expect(page).to have_current_path(active_explore_projects_path(sort: 'stars_desc'))
          end

          context 'when `retire_trending_projects` flag is disabled' do
            before do
              stub_feature_flags(retire_trending_projects: false)
              visit(trending_explore_projects_path)
            end

            it 'shows active trending projects' do
              expect(page).to have_content(public_project.title)
              expect(page).to have_content(internal_project.title)
              expect(page).not_to have_content(private_project.title)
              expect(page).not_to have_content(archived_project.title)
            end
          end
        end

        context 'when `explore_projects_vue` flag is disabled' do
          before do
            stub_feature_flags(explore_projects_vue: false)

            visit(explore_projects_path)
          end

          shared_examples 'empty search results' do
            it 'shows correct empty state message', :js do
              search('zzzzzzzzzzzzzzzzzzz')

              expect(page).to have_content('Explore public groups to find projects to contribute to')
            end
          end

          shared_examples 'minimum search length' do
            it 'shows a prompt to enter a longer search term', :js do
              search('z')

              expect(page).to have_content('Enter at least three characters to search')
            end
          end

          context 'when viewing public projects' do
            before do
              visit(explore_projects_path)
            end

            include_examples 'shows public and internal projects'
            include_examples 'empty search results'
            include_examples 'minimum search length'
          end

          context 'when viewing most starred projects' do
            before do
              visit(starred_explore_projects_path)
            end

            include_examples 'shows public and internal projects'
            include_examples 'empty search results'
            include_examples 'minimum search length'
          end

          context 'when viewing trending projects' do
            it 'redirects to active projects page' do
              visit trending_explore_projects_path
              expect(page).to have_current_path(active_explore_projects_path(sort: 'stars_desc'))
            end

            context 'when `retire_trending_projects` flag is disabled' do
              before do
                stub_feature_flags(retire_trending_projects: false)
                visit(trending_explore_projects_path)
              end

              include_examples 'shows public projects'
              include_examples 'empty search results'
              include_examples 'minimum search length'
            end
          end
        end
      end
    end
  end

  def search(term)
    gl_filtered_search_set_input(term, submit: true)
  end
end
