# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)

      sign_in(user)

      visit project_work_items_path(project, work_items_path: work_item.id)
    end

    it_behaves_like 'work items status'
    it_behaves_like 'work items assignees'
    it_behaves_like 'work items labels'
    it_behaves_like 'work items comments'
    it_behaves_like 'work items description'
  end
end
