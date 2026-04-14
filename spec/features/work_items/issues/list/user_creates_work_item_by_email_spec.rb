# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work items > User creates work item by email', feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  before_all do
    project.add_developer(user)
  end

  before do
    create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    sign_in(user)
  end

  describe 'new issue by email', :js do
    shared_examples 'show the email in the modal' do
      let(:issue) { create(:issue, project: project) }

      before do
        project.issues << issue
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")

        visit project_work_items_path(project)

        find_by_testid('work-items-list-more-actions-dropdown').click

        click_button('Email work item to this project')
      end

      it 'click the button to show modal for the new email' do
        within_modal do
          email = project.new_issuable_address(user, 'issue')

          expect(page.find('input[type="text"]').value).to eq email
        end
      end
    end

    context 'with existing issues' do
      let!(:issue) { create(:issue, project: project, author: user) }

      it_behaves_like 'show the email in the modal'
    end

    context 'without existing issues' do
      it_behaves_like 'show the email in the modal'
    end
  end
end
