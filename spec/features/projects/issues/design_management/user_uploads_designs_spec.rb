# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads new design', :js do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { project.owner }
  let(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
  end

  context 'design_management_moved flag disabled' do
    before do
      enable_design_management(feature_enabled)
      stub_feature_flags(design_management_moved: false)
      visit project_issue_path(project, issue)

      click_link 'Designs'

      wait_for_requests
    end

    context "when the feature is available" do
      let(:feature_enabled) { true }

      it 'uploads designs' do
        upload_design(logo_fixture, count: 1)

        expect(page).to have_selector('.js-design-list-item', count: 1)

        within first('#designs-tab .js-design-list-item') do
          expect(page).to have_content('dk.png')
        end

        upload_design(gif_fixture, count: 2)

        # Known bug in the legacy implementation: new designs are inserted
        # in the beginning on the frontend.
        expect(page).to have_selector('.js-design-list-item', count: 2)
        expect(page.all('.js-design-list-item').map(&:text)).to eq(['banana_sample.gif', 'dk.png'])
      end
    end

    context 'when the feature is not available' do
      let(:feature_enabled) { false }

      it 'shows the message about requirements' do
        expect(page).to have_content("To upload designs, you'll need to enable LFS.")
      end
    end
  end

  context 'design_management_moved flag enabled' do
    before do
      enable_design_management(feature_enabled)
      stub_feature_flags(design_management_moved: true)
      visit project_issue_path(project, issue)
    end

    context "when the feature is available" do
      let(:feature_enabled) { true }

      it 'uploads designs' do
        upload_design(logo_fixture, count: 1)

        expect(page).to have_selector('.js-design-list-item', count: 1)

        within first('[data-testid="designs-root"] .js-design-list-item') do
          expect(page).to have_content('dk.png')
        end

        upload_design(gif_fixture, count: 2)

        expect(page).to have_selector('.js-design-list-item', count: 2)
        expect(page.all('.js-design-list-item').map(&:text)).to eq(['dk.png', 'banana_sample.gif'])
      end
    end

    context 'when the feature is not available' do
      let(:feature_enabled) { false }

      it 'shows the message about requirements' do
        expect(page).to have_content("To upload designs, you'll need to enable LFS.")
      end
    end
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end

  def gif_fixture
    Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
  end

  def upload_design(fixture, count:)
    attach_file(:design_file, fixture, match: :first, make_visible: true)

    wait_for('designs uploaded') do
      issue.reload.designs.count == count
    end
  end
end
