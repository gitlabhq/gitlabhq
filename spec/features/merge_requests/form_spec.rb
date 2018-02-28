require 'rails_helper'

describe 'New/edit merge request', :js do
  include ProjectForksHelper

  let!(:project)     { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(project, nil, repository: true) }
  let!(:user)        { create(:user) }
  let!(:user2)       { create(:user) }
  let!(:milestone)   { create(:milestone, project: project) }
  let!(:label)       { create(:label, project: project) }
  let!(:label2)      { create(:label, project: project) }

  before do
    project.add_master(user)
    project.add_master(user2)
  end

  context 'owned projects' do
    before do
      sign_in(user)
    end

    context 'new merge request' do
      before do
        visit project_new_merge_request_path(
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
          click_link user2.name
        end
        expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user2.id.to_s)
        page.within '.js-assignee-search' do
          expect(page).to have_content user2.name
        end

        find('a', text: 'Assign to me').click
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

        page.within '.breadcrumbs' do
          merge_request = MergeRequest.find_by(source_branch: 'fix')

          expect(page).to have_text("Merge Requests #{merge_request.to_reference}")
        end
      end

      it 'description has autocomplete' do
        find('#merge_request_description').native.send_keys('')
        fill_in 'merge_request_description', with: '@'

        expect(page).to have_selector('.atwho-view')
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

        visit edit_project_merge_request_path(project, merge_request)
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

      it 'description has autocomplete' do
        find('#merge_request_description').native.send_keys('')
        fill_in 'merge_request_description', with: '@'

        expect(page).to have_selector('.atwho-view')
      end
    end
  end

  context 'forked project' do
    before do
      forked_project.add_master(user)
      sign_in(user)
    end

    context 'new merge request' do
      before do
        visit project_new_merge_request_path(
          forked_project,
          merge_request: {
            source_project_id: forked_project.id,
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
                                 source_project: forked_project,
                                 target_project: project,
                                 source_branch: 'fix',
                                 target_branch: 'master'
                              )

        visit edit_project_merge_request_path(project, merge_request)
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
