# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Group milestone' do
      include Support::Dates

      let(:title) { 'Group milestone' }
      let(:description) { 'This milestone tests out group milestones.' }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }

      before do
        Flow::Login.sign_in
      end

      it 'creates a group milestone', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1148' do
        group_milestone = Resource::GroupMilestone.fabricate_via_browser_ui! do |milestone|
          milestone.title = title
          milestone.description = description
          milestone.start_date = start_date
          milestone.due_date = due_date
        end

        Page::Group::Menu.perform(&:go_to_milestones)
        Page::Group::Milestone::Index.perform do |milestone_list|
          expect(milestone_list).to have_milestone(group_milestone)

          milestone_list.click_milestone(group_milestone)
        end

        Page::Milestone::Show.perform do |milestone|
          expect(milestone).to have_element(:milestone_title_content, text: title)
          expect(milestone).to have_element(:milestone_description_content, text: description)
          expect(milestone).to have_start_date(start_date)
          expect(milestone).to have_due_date(due_date)
        end
      end
    end
  end
end
