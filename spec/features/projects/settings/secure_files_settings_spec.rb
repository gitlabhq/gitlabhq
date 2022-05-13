# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure Files Settings' do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, creator_id: maintainer.id) }

  before_all do
    project.add_maintainer(maintainer)
  end

  context 'when the :ci_secure_files feature flag is enabled' do
    before do
      stub_feature_flags(ci_secure_files: true)

      sign_in(user)
      visit project_settings_ci_cd_path(project)
    end

    context 'authenticated user with admin permissions' do
      let(:user) { maintainer }

      it 'shows the secure files settings' do
        expect(page).to have_content('Secure Files')
      end
    end
  end

  context 'when the :ci_secure_files feature flag is disabled' do
    before do
      stub_feature_flags(ci_secure_files: false)

      sign_in(user)
      visit project_settings_ci_cd_path(project)
    end

    context 'authenticated user with admin permissions' do
      let(:user) { maintainer }

      it 'does not shows the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end
  end
end
