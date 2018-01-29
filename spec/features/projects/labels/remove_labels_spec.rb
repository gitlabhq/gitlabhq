require 'spec_helper'

describe 'Removing labels', :js do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let(:project)  { create(:project, :public, namespace: group) }
  let!(:bug)     { create(:label, project: project, title: 'bug') }
  let!(:test_label)    { create(:label, project: project, title: 'test') }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'with a label list' do
    before do
      visit project_labels_path(project)
    end

    it 'Deletes all labels' do
      delete_label(bug.title)
      wait_for_requests
      delete_label(test_label.title)
      wait_for_requests
      expect(find('.empty-state.labels')).not_to be_nil
    end
  end

  def delete_label(label_title)
    find('#delete-label-modal.modal', visible: false) # wait for Vue component to be loaded
    find(".js-delete-project-label[data-label-title=\"#{label_title}\"]" % { label_title: label_title }).click

    page.within '#delete-label-modal' do
      click_on 'Delete Label'
    end
  end
end
