# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Issue', :js, feature_category: :source_code_management do
  include ContentEditorHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issue_path(project, issue)
    close_rich_text_promo_popover_if_present
  end

  it_behaves_like 'thread comments for issue, epic and merge request', 'issue'
end
