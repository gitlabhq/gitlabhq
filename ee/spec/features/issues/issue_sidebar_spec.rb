require 'rails_helper'

feature 'Issue Sidebar' do
  include MobileHelpers

  let(:group) { create(:group, :nested) }
  let(:project) { create(:project, :public, namespace: group) }
  let!(:user) { create(:user)}
  let!(:label) { create(:label, project: project, title: 'bug') }
  let(:issue) { create(:labeled_issue, project: project, labels: [label]) }

  before do
    sign_in(user)
  end

  context 'updating weight', :js do
    before do
      project.add_master(user)
      visit_issue(project, issue)
    end

    it 'updates weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'updates weight in sidebar to no weight' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end

        click_link 'remove weight'

        page.within '.value' do
          expect(page).to have_content 'None'
        end
      end
    end
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end
end
