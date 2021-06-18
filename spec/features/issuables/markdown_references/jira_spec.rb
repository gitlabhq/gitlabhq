# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Jira", :js do
  let(:user) { create(:user) }
  let(:actual_project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, target_project: actual_project, source_project: actual_project) }
  let(:issue_actual_project) { create(:issue, project: actual_project) }
  let!(:other_project) { create(:project, :public) }
  let!(:issue_other_project) { create(:issue, project: other_project) }
  let(:issues) { [issue_actual_project, issue_other_project] }

  shared_examples "correct references" do
    before do
      remotelink = double(:remotelink, all: [], build: double(save!: true))

      stub_request(:get, "https://jira.example.com/rest/api/2/issue/JIRA-5")
      stub_request(:post, "https://jira.example.com/rest/api/2/issue/JIRA-5/comment")
      allow_next_instance_of(JIRA::Resource::Issue) do |instance|
        allow(instance).to receive(:remotelink).and_return(remotelink)
      end

      sign_in(user)

      visit(merge_request_path(merge_request))

      build_note
    end

    it "creates a link to the referenced issue on the preview" do
      find(".js-md-preview-button").click

      wait_for_requests

      page.within(".md-preview-holder") do
        links_expectations
      end
    end

    it "creates a link to the referenced issue after submit" do
      click_button("Comment")

      wait_for_requests

      page.within("#diff-notes-app") do
        links_expectations
      end
    end

    it "creates a note on the referenced issues", :sidekiq_might_not_need_inline do
      click_button("Comment")

      wait_for_requests

      if referenced_issues.include?(issue_actual_project)
        visit(issue_path(issue_actual_project))

        page.within("#notes") do
          expect(page).to have_content("#{user.to_reference} mentioned in merge request #{merge_request.to_reference}")
        end
      end

      if referenced_issues.include?(issue_other_project)
        visit(issue_path(issue_other_project))

        page.within("#notes") do
          expect(page).to have_content("#{user.to_reference} mentioned in merge request #{merge_request.to_reference(other_project)}")
        end
      end
    end
  end

  context "when internal issues tracker is enabled for the other project" do
    context "when only internal issues tracker is enabled for the actual project" do
      include_examples "correct references" do
        let(:referenced_issues) { [issue_actual_project, issue_other_project] }
        let(:jira_referenced) { false }
      end
    end

    context "when both external and internal issues trackers are enabled for the actual project" do
      before do
        create(:jira_integration, project: actual_project)
      end

      include_examples "correct references" do
        let(:referenced_issues) { [issue_actual_project, issue_other_project] }
        let(:jira_referenced) { true }
      end
    end

    context "when only external issues tracker is enabled for the actual project" do
      let(:actual_project) { create(:project, :public, :repository, :issues_disabled) }

      before do
        create(:jira_integration, project: actual_project)
      end

      include_examples "correct references" do
        let(:referenced_issues) { [issue_other_project] }
        let(:jira_referenced) { true }
      end
    end

    context "when no tracker is enabled for the actual project" do
      let(:actual_project) { create(:project, :public, :repository, :issues_disabled) }

      include_examples 'correct references' do
        let(:referenced_issues) { [issue_other_project] }
        let(:jira_referenced) { false }
      end
    end
  end

  context "when internal issues tracker is disabled for the other project" do
    let(:other_project) { create(:project, :public, :repository, :issues_disabled) }

    context "when only internal issues tracker is enabled for the actual project" do
      include_examples "correct references" do
        let(:referenced_issues) { [issue_actual_project] }
        let(:jira_referenced) { false }
      end
    end

    context "when both external and internal issues trackers are enabled for the actual project" do
      before do
        create(:jira_integration, project: actual_project)
      end

      include_examples "correct references" do
        let(:referenced_issues) { [issue_actual_project] }
        let(:jira_referenced) { true }
      end
    end

    context "when only external issues tracker is enabled for the actual project" do
      let(:actual_project) { create(:project, :public, :repository, :issues_disabled) }

      before do
        create(:jira_integration, project: actual_project)
      end

      include_examples "correct references" do
        let(:referenced_issues) { [] }
        let(:jira_referenced) { true }
      end
    end

    context "when no issues tracker is enabled for the actual project" do
      let(:actual_project) { create(:project, :public, :repository, :issues_disabled) }

      include_examples "correct references" do
        let(:referenced_issues) { [] }
        let(:jira_referenced) { false }
      end
    end
  end

  private

  def build_note
    markdown = <<~HEREDOC
      Referencing internal issue #{issue_actual_project.to_reference},
      cross-project #{issue_other_project.to_reference(actual_project)} external JIRA-5
      and non existing ##{non_existing_record_iid}
    HEREDOC

    page.within("#diff-notes-app") do
      fill_in("note-body", with: markdown)
    end
  end

  def links_expectations
    issues.each do |issue|
      if referenced_issues.include?(issue)
        expect(page).to have_link(issue.to_reference, href: issue_path(issue))
      else
        expect(page).not_to have_link(issue.to_reference, href: issue_path(issue))
      end
    end

    if jira_referenced
      expect(page).to have_link("JIRA-5", href: "https://jira.example.com/browse/JIRA-5")
    else
      expect(page).not_to have_link("JIRA-5", href: "https://jira.example.com/browse/JIRA-5")
    end

    expect(page).not_to have_link("##{non_existing_record_iid}")
  end
end
