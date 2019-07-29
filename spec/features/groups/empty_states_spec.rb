# frozen_string_literal: true

require 'spec_helper'

describe 'Group empty states' do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :developer, user: create(:user), group: group ).user }

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
            expect(page).not_to have_selector('.empty-state')
          end

          it "displays link to create new #{issuable} when no open #{issuable} is found" do
            create("closed_#{issuable}", project_relation => project)
            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project)

            page.within(find('.empty-state')) do
              expect(page).to have_content(/There are no open #{issuable.to_s.humanize.downcase}/)
              expect(page).to have_selector("#new_#{issuable}_body_link")
            end
          end

          it 'displays link to create new issue when the current search gave no results' do
            create(issuable, project_relation => project)

            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project, author_username: 'foo', scope: 'all', state: 'opened')

            page.within(find('.empty-state')) do
              expect(page).to have_content(/Sorry, your filter produced no results/)
              new_issuable_path = issuable == :issue ? 'new_project_issue_path' : 'project_new_merge_request_path'

              path = public_send(new_issuable_path, project)

              expect(page).to have_selector("#new_#{issuable}_body_link[href='#{path}']")
            end
          end

          it "displays conditional text when no closed #{issuable} is found" do
            create(issuable, project_relation => project)

            issuable_link_fn = "project_#{issuable}s_path"

            visit public_send(issuable_link_fn, project, state: 'closed')

            page.within(find('.empty-state')) do
              expect(page).to have_content(/There are no closed #{issuable.to_s.humanize.downcase}/)
            end
          end
        end

        context "the project has no #{issuable_name}s", :js do
          before do
            visit path
          end

          it 'displays an empty state' do
            expect(page).to have_selector('.empty-state')
          end

          it "shows a new #{issuable_name} button" do
            within '.empty-state' do
              expect(page).to have_content("create #{issuable_name}")
            end
          end

          it "the new #{issuable_name} button opens a project dropdown" do
            within '.empty-state' do
              find('.new-project-item-select-button').click
            end

            expect(page).to have_selector('.ajax-project-dropdown')
          end
        end
      end

      shared_examples "no projects" do
        it 'displays an empty state' do
          expect(page).to have_selector('.empty-state')
        end

        it "does not show a new #{issuable_name} button" do
          within '.empty-state' do
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
              expect(page).not_to have_selector('.empty-state')
            end
          end

          context "the project has no #{issuable_name}s" do
            before do
              visit path
            end

            it 'displays an empty state' do
              expect(page).to have_selector('.empty-state')
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
