require 'spec_helper'

feature 'Labels Hierarchy', :js, :nested_groups do
  let!(:user) { create(:user) }
  let!(:grandparent) { create(:group) }
  let!(:parent) { create(:group, parent: grandparent) }
  let!(:child) { create(:group, parent: parent) }
  let!(:project_1) { create(:project, namespace: child) }

  let!(:grandparent_group_label) { create(:group_label, group: grandparent, title: 'Label_1') }
  let!(:parent_group_label) { create(:group_label, group: parent, title: 'Label_2') }
  let!(:child_group_label) { create(:group_label, group: child, title: 'Label_3') }
  let!(:project_label_1) { create(:label, project: project_1, title: 'Label_4') }

  let!(:labeled_issue_1) { create(:labeled_issue, project: project_1, labels: [grandparent_group_label, parent_group_label, child_group_label]) }
  let!(:labeled_issue_2) { create(:labeled_issue, project: project_1, labels: [grandparent_group_label, parent_group_label]) }
  let!(:labeled_issue_3) { create(:labeled_issue, project: project_1, labels: [grandparent_group_label, parent_group_label, child_group_label, project_label_1]) }
  let!(:not_labeled) { create(:issue, project: project_1) }

  before do
    grandparent.add_owner(user)

    sign_in(user)
  end

  shared_examples 'filter for scoped boards' do |project = false|
    it 'scopes board to ancestor and descendant labels' do
      labels = [grandparent_group_label, parent_group_label, child_group_label]
      labels.push(project_label_1) if project

      labels.each do |label|
        page.within('.filter-dropdown-container') do
          find('button', text: "Edit board").click
        end

        page.within('.js-labels-block') do
          find('.edit-link').click
        end

        wait_for_requests

        find('a.label-item', text: label.title).click

        find('button', text: "Save changes").click

        wait_for_requests

        expect(page).to have_selector('.card', count: label.issues.count)

        label.issues.each do |issue|
          expect(page).to have_selector('.card-title') do |card|
            expect(card).to have_selector('a', text: issue.title)
          end
        end
      end
    end
  end

  context 'scoped boards' do
    context 'for group boards' do
      let(:board) { create(:board, group: parent) }

      before do
        visit group_board_path(parent, board)

        wait_for_requests
      end

      it_behaves_like 'filter for scoped boards'
    end

    context 'for project boards' do
      let(:board) { create(:board, project: project_1) }

      before do
        visit project_board_path(project_1, board)

        wait_for_requests
      end

      it_behaves_like 'filter for scoped boards', true
    end
  end
end
