# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User browse group projects page' do
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

        it 'renders projects list' do
          visit projects_group_path(group)

          expect(page).to have_link project.name
          expect(page).to have_css('span.badge.badge-warning', text: 'archived')
        end
      end
    end
  end
end
