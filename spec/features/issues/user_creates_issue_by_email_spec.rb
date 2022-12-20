# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User creates issue by email', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  before do
    sign_in(user)

    project.add_developer(user)
  end

  describe 'new issue by email', :js do
    shared_examples 'show the email in the modal' do
      let(:issue) { create(:issue, project: project) }

      before do
        project.issues << issue
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")

        visit project_issues_path(project)
        click_button('Email a new issue')
      end

      it 'click the button to show modal for the new email' do
        page.within '#issuable-email-modal' do
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
