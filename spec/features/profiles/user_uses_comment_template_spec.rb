# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses comment template', :js,
  feature_category: :user_profile do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    project.add_owner(user)

    sign_in(user)
  end

  it 'applies comment template' do
    visit project_merge_request_path(merge_request.project, merge_request)

    find('.js-comment-template-toggle').click

    wait_for_requests

    find('.gl-new-dropdown-item').click

    expect(find('.note-textarea').value).to eq(saved_reply.content)
  end
end
