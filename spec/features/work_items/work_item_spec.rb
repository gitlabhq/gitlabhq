# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)

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
    end
  end
end
