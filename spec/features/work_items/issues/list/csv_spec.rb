# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues csv', :js, feature_category: :team_planning do
  include FilteredSearchHelpers
  include Features::SortingHelpers

  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :public) }
  let_it_be(:idea_label) { create(:label, project: project, title: 'Idea') }
  let_it_be(:feature_label) { create(:label, project: project, title: 'Feature', priority: 10) }
  let_it_be_with_reload(:issue) { create(:issue, project: project, author: user) }

  before do
    create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    sign_in(user)
    visit project_work_items_path(project)
  end

  def wait_for_list_to_load
    expect(page).to have_selector('.issue')
  end

  def request_csv
    wait_for_list_to_load

    click_button 'Actions'
    click_button 'Export as CSV'
    click_on 'Export work items'

    # Wait for the async export to finish before inspecting the result.
    expect(page).to have_css("[data-testid='alert-success']")
  end

  def attachment
    ActionMailer::Base.deliveries.last.attachments.first
  end

  def csv
    CSV.parse(attachment.decode_body, headers: true)
  end

  it 'triggers an email export' do
    expect(IssuableExportCsvWorker).to receive(:perform_async).with(:work_item, user.id, project.id, anything)

    request_csv
  end

  it "doesn't send request params to ExportCsvWorker" do
    expect(IssuableExportCsvWorker).to receive(:perform_async)
      .with(:work_item, anything, anything, hash_excluding("controller" => anything, "action" => anything))

    request_csv
  end

  it 'displays flash message', :aggregate_failures do
    request_csv

    expect(page).to have_content 'Your CSV export request has succeeded'
    expect(page).to have_content "emailed to #{user.notification_email_or_default}"
  end

  it 'includes a csv attachment', :sidekiq_inline do
    request_csv

    expect(attachment.content_type).to include('text/csv')
  end

  it 'ignores pagination', :sidekiq_inline do
    create_list(:issue, 30, project: project, author: user)

    request_csv

    expect(csv.count).to eq 31
  end

  it 'uses filters from issue index', :sidekiq_inline do
    closed_issue = create(:issue, :closed, project: project, author: user)

    visit project_work_items_path(project, state: 'closed')
    request_csv

    expect(csv.count).to eq 1
    expect(csv.first['IID']).to eq closed_issue.iid.to_s
  end

  it 'ignores sorting from issue index', :sidekiq_inline do
    issue2 = create(:labeled_issue, project: project, author: user, labels: [feature_label])

    click_button 'Display'
    pajamas_sort_by 'Label priority', from: 'Created date'
    send_keys :escape # close the display settings drawer so it does not overlay the CSV export buttons
    request_csv

    expected = [issue.iid.to_s, issue2.iid.to_s]
    expect(csv.map { |row| row['IID'] }).to eq expected
  end

  it 'uses array filters, such as label_name', :sidekiq_inline do
    issue.update!(labels: [idea_label])

    select_tokens 'Label', '||', feature_label.title, idea_label.title, submit: true
    request_csv

    expect(csv.count).to eq 1
  end

  context "with multiple issue authors" do
    let_it_be(:user2) { create(:user, developer_of: project) }
    let_it_be(:issue2) { create(:issue, project: project, author: user2) }

    it 'exports issues by selected author', :sidekiq_inline do
      select_tokens 'Author', '=', user2.username, submit: true
      request_csv

      expect(csv.count).to eq 1
    end

    it 'exports issues by selected multiple authors', :sidekiq_inline do
      select_tokens 'Author', '||', user2.username, user.username, submit: true
      request_csv

      expect(csv.count).to eq 2
    end

    it 'does not export issues by excluded multiple authors', :sidekiq_inline do
      user3 = create(:user, developer_of: project)
      issue3 = create(:issue, project: project, author: user3)

      select_tokens 'Author', '!=', user.username, user2.username, submit: true
      request_csv

      expect(csv.count).to eq 1
      expect(csv.first['IID']).to eq issue3.iid.to_s
    end
  end
end
