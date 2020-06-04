# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesChannel do
  let_it_be(:issue) { create(:issue) }

  it 'rejects when project path is invalid' do
    subscribe(project_path: 'invalid_project_path', iid: issue.iid)

    expect(subscription).to be_rejected
  end

  it 'rejects when iid is invalid' do
    subscribe(project_path: issue.project.full_path, iid: non_existing_record_iid)

    expect(subscription).to be_rejected
  end

  it 'rejects when the user does not have access' do
    stub_action_cable_connection current_user: nil

    subscribe(project_path: issue.project.full_path, iid: issue.iid)

    expect(subscription).to be_rejected
  end

  it 'subscribes to a stream when the user has access' do
    stub_action_cable_connection current_user: issue.author

    subscribe(project_path: issue.project.full_path, iid: issue.iid)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(issue)
  end
end
