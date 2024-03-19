# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes branch", :js, feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it "deletes branch", :js do
    visit(project_branches_path(project))

    branch_search = find('input[data-testid="branch-search"]')

    branch_search.set('improve/awesome')
    branch_search.native.send_keys(:enter)

    page.within(".js-branch-improve\\/awesome") do
      click_button 'More actions'
      find_by_testid('delete-branch-button').click
    end

    accept_gl_confirm(button_text: 'Yes, delete branch')

    wait_for_requests

    expect(page).to have_content('Branch was deleted')
  end
end
