# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)
      project.add_developer(other_user)

      sign_in(user)

      visit project_work_items_path(project, work_items_path: work_item.id)
    end

    context 'in work item description' do
      it 'shows GFM autocomplete', :aggregate_failures do
        click_button "Edit description"

        find('[aria-label="Description"]').send_keys("@#{user.username}")

        wait_for_requests

        page.within('.atwho-container') do
          expect(page).to have_text(user.name)
        end
      end

      it 'shows conflict message when description changes', :aggregate_failures do
        click_button "Edit description"
        scroll_to(find('[aria-label="Description"]'))

        # without this for some reason the test fails when running locally
        sleep 1

        ::WorkItems::UpdateService.new(
          project: work_item.project,
          current_user: other_user,
          params: { description: "oh no!" }
        ).execute(work_item)

        work_item.reload

        find('[aria-label="Description"]').send_keys("oh yeah!")

        warning = 'Someone edited the description at the same time you did.'
        expect(page.find('[data-testid="work-item-description-conflicts"]')).to have_text(warning)

        click_button "Save and overwrite"

        expect(page.find('[data-testid="work-item-description"]')).to have_text("oh yeah!")
      end
    end
  end
end
