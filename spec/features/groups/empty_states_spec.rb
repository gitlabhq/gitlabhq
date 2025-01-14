# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group empty states', feature_category: :groups_and_projects do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :developer, user: create(:user), group: group).user }

  before do
    sign_in(user)
  end

  [:issue, :merge_request].each do |issuable|
    issuable_name = issuable.to_s.humanize.downcase
    project_relation = issuable == :issue ? :project : :source_project

    context "for #{issuable_name}s" do
      let(:path) { public_send(:"#{issuable}s_group_path", group) }

      context 'group has a project' do
        let(:project) { create(:project, namespace: group) }

        before do
          project.add_maintainer(user)
        end

        context "the project has #{issuable_name}s" do
          it 'does not display an empty state' do
            create(issuable, project_relation => project)

            visit path
            expect(page).not_to have_selector('[data-testid="issuable-empty-state"]')
          end

          it "displays link to create new #{issuable} when no open #{issuable} is found", :js do
            create("closed_#{issuable}", project_relation => project)
            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project)

            wait_for_all_requests

            within_testid('issuable-empty-state') do
              expect(page).to have_content(/There are no open #{issuable.to_s.humanize.downcase}/)
              new_issuable_path = issuable == :issue ? 'new_project_issue_path' : 'project_new_merge_request_path'

              path = public_send(new_issuable_path, project)

              expect(page.find('a')['href']).to have_content(path)
            end
          end

          it 'displays link to create new issue when the current search gave no results', :js do
            create(issuable, project_relation => project)

            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project, author_username: 'foo', scope: 'all', state: 'opened')

            wait_for_all_requests

            expect(page.find('.gl-empty-state')).to have_content("No results found")
          end

          it "displays conditional text when no closed #{issuable} is found", :js do
            create(issuable, project_relation => project)

            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project, state: 'closed')

            wait_for_all_requests

            within_testid('issuable-empty-state') do
              expect(page).to have_content(/There are no closed #{issuable.to_s.humanize.downcase}/)
            end
          end
        end

        context "the project has no #{issuable_name}s", :js do
          before do
            visit path
          end

          it 'displays an empty state' do
            expect(page).to have_selector('[data-testid="issuable-empty-state"]')
          end

          it "shows a new #{issuable_name} button", skip: 'Button does not exist in Vue version' do
            expect(page).to have_content("create #{issuable_name}")
          end

          it "the new #{issuable_name} button opens a project dropdown", skip: 'Button does not exist in Vue version' do
            click_button "Select project to create #{issuable_name}"

            expect(page).to have_button project.name
          end
        end
      end

      shared_examples "no projects" do
        it 'displays an empty state', :js do
          expect(page).to have_selector('[data-testid="issuable-empty-state"]')
        end

        it "does not show a new #{issuable_name} button", :js do
          within_testid('issuable-empty-state') do
            expect(page).not_to have_link("create #{issuable_name}")
          end
        end
      end

      context 'group without a project' do
        context 'group has a subgroup' do
          let(:subgroup) { create(:group, parent: group) }
          let(:subgroup_project) { create(:project, namespace: subgroup) }

          context "the project has #{issuable_name}s" do
            before do
              create(issuable, project_relation => subgroup_project)

              visit path
            end

            it 'does not display an empty state' do
              expect(page).not_to have_selector('[data-testid="issuable-empty-state"]')
            end
          end

          context "the project has no #{issuable_name}s" do
            before do
              visit path
            end

            it 'displays an empty state', :js do
              expect(page).to have_selector('[data-testid="issuable-empty-state"]')
            end
          end
        end

        context 'group has no subgroups' do
          before do
            visit path
          end

          it_behaves_like "no projects"
        end
      end

      context 'group has only a project with issues disabled' do
        let(:project_with_issues_disabled) { create(:empty_project, :issues_disabled, group: group) }

        before do
          visit path
        end

        it_behaves_like "no projects"
      end
    end
  end
end
