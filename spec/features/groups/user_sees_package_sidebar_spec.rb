# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > sidebar' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_developer(user)
    sign_in(user)
  end

  context 'Package menu' do
    context 'when container registry is enabled' do
      before do
        stub_container_registry_config(enabled: true)
        visit group_path(group)
      end

      it 'shows main menu' do
        within '.nav-sidebar' do
          expect(page).to have_link(_('Packages'))
        end
      end

      it 'has container registry link' do
        within '.nav-sidebar' do
          expect(page).to have_link(_('Container Registry'))
        end
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
        visit group_path(group)
      end

      it 'does not have container registry link' do
        within '.nav-sidebar' do
          expect(page).not_to have_link(_('Container Registry'))
        end
      end
    end
  end
end
