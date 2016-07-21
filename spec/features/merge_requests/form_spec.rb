require 'rails_helper'

describe 'New/edit merge request', feature: true, js: true do
  let!(:project)   { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:fork_project) { create(:project, forked_from_project: project) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }

  before do
    project.team << [user, :master]
  end

  context 'owned projects' do
    before do
      login_as(user)
    end

    context 'new merge request' do
      before do
        visit new_namespace_project_merge_request_path(
          project.namespace,
          project,
          merge_request: {
            source_project_id: project.id,
            target_project_id: project.id,
            source_branch: 'fix',
            target_branch: 'master'
          })
      end

      it 'creates new merge request' do
        click_button 'Assignee'
        page.within '.dropdown-menu-user' do
          click_link user.name
        end
        expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user.id.to_s)
        page.within '.js-assignee-search' do
          expect(page).to have_content user.name
        end

        click_button 'Milestone'
        page.within '.issue-milestone' do
          click_link milestone.title
        end
        expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
        page.within '.js-milestone-select' do
          expect(page).to have_content milestone.title
        end

        click_button 'Labels'
        page.within '.dropdown-menu-labels' do
          click_link label.title
          click_link label2.title
        end
        page.within '.js-label-select' do
          expect(page).to have_content label.title
        end
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

        click_button 'Submit merge request'

        page.within '.issuable-sidebar' do
          page.within '.assignee' do
            expect(page).to have_content user.name
          end

          page.within '.milestone' do
            expect(page).to have_content milestone.title
          end

          page.within '.labels' do
            expect(page).to have_content label.title
            expect(page).to have_content label2.title
          end
        end
      end
    end

    context 'edit merge request' do
      before do
        merge_request = create(:merge_request,
                                 source_project: project,
                                 target_project: project,
                                 source_branch: 'fix',
                                 target_branch: 'master'
                              )

        visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
      end

      it 'updates merge request' do
        click_button 'Assignee'
        page.within '.dropdown-menu-user' do
          click_link user.name
        end
        expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user.id.to_s)
        page.within '.js-assignee-search' do
          expect(page).to have_content user.name
        end

        click_button 'Milestone'
        page.within '.issue-milestone' do
          click_link milestone.title
        end
        expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
        page.within '.js-milestone-select' do
          expect(page).to have_content milestone.title
        end

        click_button 'Labels'
        page.within '.dropdown-menu-labels' do
          click_link label.title
          click_link label2.title
        end
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)
        page.within '.js-label-select' do
          expect(page).to have_content label.title
        end

        click_button 'Save changes'

        page.within '.issuable-sidebar' do
          page.within '.assignee' do
            expect(page).to have_content user.name
          end

          page.within '.milestone' do
            expect(page).to have_content milestone.title
          end

          page.within '.labels' do
            expect(page).to have_content label.title
            expect(page).to have_content label2.title
          end
        end
      end
    end
  end

  context 'forked project' do
    before do
      fork_project.team << [user, :master]
      login_as(user)
    end

    context 'new merge request' do
      before do
        visit new_namespace_project_merge_request_path(
          fork_project.namespace,
          fork_project,
          merge_request: {
            source_project_id: fork_project.id,
            target_project_id: project.id,
            source_branch: 'fix',
            target_branch: 'master'
          })
      end

      it 'creates new merge request' do
        click_button 'Assignee'
        page.within '.dropdown-menu-user' do
          click_link user.name
        end
        expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user.id.to_s)
        page.within '.js-assignee-search' do
          expect(page).to have_content user.name
        end

        click_button 'Milestone'
        page.within '.issue-milestone' do
          click_link milestone.title
        end
        expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
        page.within '.js-milestone-select' do
          expect(page).to have_content milestone.title
        end

        click_button 'Labels'
        page.within '.dropdown-menu-labels' do
          click_link label.title
          click_link label2.title
        end
        page.within '.js-label-select' do
          expect(page).to have_content label.title
        end
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

        click_button 'Submit merge request'

        page.within '.issuable-sidebar' do
          page.within '.assignee' do
            expect(page).to have_content user.name
          end

          page.within '.milestone' do
            expect(page).to have_content milestone.title
          end

          page.within '.labels' do
            expect(page).to have_content label.title
            expect(page).to have_content label2.title
          end
        end
      end
    end

    context 'edit merge request' do
      before do
        merge_request = create(:merge_request,
                                 source_project: fork_project,
                                 target_project: project,
                                 source_branch: 'fix',
                                 target_branch: 'master'
                              )

        visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
      end

      it 'should update merge request' do
        click_button 'Assignee'
        page.within '.dropdown-menu-user' do
          click_link user.name
        end
        expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user.id.to_s)
        page.within '.js-assignee-search' do
          expect(page).to have_content user.name
        end

        click_button 'Milestone'
        page.within '.issue-milestone' do
          click_link milestone.title
        end
        expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
        page.within '.js-milestone-select' do
          expect(page).to have_content milestone.title
        end

        click_button 'Labels'
        page.within '.dropdown-menu-labels' do
          click_link label.title
          click_link label2.title
        end
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
        expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)
        page.within '.js-label-select' do
          expect(page).to have_content label.title
        end

        click_button 'Save changes'

        page.within '.issuable-sidebar' do
          page.within '.assignee' do
            expect(page).to have_content user.name
          end

          page.within '.milestone' do
            expect(page).to have_content milestone.title
          end

          page.within '.labels' do
            expect(page).to have_content label.title
            expect(page).to have_content label2.title
          end
        end
      end
    end
  end
end
