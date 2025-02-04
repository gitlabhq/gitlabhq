# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User browse group projects page', feature_category: :groups_and_projects do
  let(:user) { create :user }
  let(:group) { create :group }

  context 'when user is owner' do
    before do
      group.add_owner(user)
    end

    context 'when user signed in' do
      before do
        sign_in(user)
      end

      context 'when group has archived project', :js do
        let!(:project) { create :project, :archived, namespace: group }

        it 'redirects to the groups overview page' do
          visit projects_group_path(group)

          expect(page).to have_current_path(group_path(group))
        end
      end
    end
  end
end
