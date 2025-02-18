# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Internal references", :js, feature_category: :team_planning do
  include Features::NotesHelpers

  let(:private_project_user) { private_project.first_owner }
  let(:private_project) { create(:project, :private, :repository) }
  let(:private_project_issue) { create(:issue, project: private_project) }
  let(:private_project_merge_request) { create(:merge_request, source_project: private_project) }
  let(:public_project_user) { public_project.first_owner }
  let(:public_project) { create(:project, :public, :repository) }
  let(:public_project_issue) { create(:issue, project: public_project) }
  let(:public_project_merge_request) { create(:merge_request, source_project: public_project) }

  context "when referencing to open issue" do
    context "from private project" do
      context "from issue" do
        before do
          sign_in(private_project_user)

          visit(project_issue_path(private_project, private_project_issue))
          wait_for_requests

          add_note("##{public_project_issue.to_reference(private_project)}")
        end

        context "when user doesn't have access to private project" do
          before do
            sign_in(public_project_user)

            visit(project_issue_path(public_project, public_project_issue))
            wait_for_requests
          end

          it { expect(page).not_to have_css(".note") }
        end
      end

      context "from merge request" do
        before do
          sign_in(private_project_user)

          visit(project_merge_request_path(private_project, private_project_merge_request))
          wait_for_requests

          add_note("##{public_project_issue.to_reference(private_project)}")
        end

        context "when user doesn't have access to private project" do
          before do
            sign_in(public_project_user)

            visit(project_issue_path(public_project, public_project_issue))
            wait_for_requests
          end

          it "doesn't show any references" do
            expect(page).not_to have_text 'Related merge requests'
          end
        end

        context "when user has access to private project" do
          before do
            visit(project_issue_path(public_project, public_project_issue))
            wait_for_requests
          end

          it "shows references", :sidekiq_might_not_need_inline do
            expect(page).to have_text 'Related merge requests 1'

            page.within('.related-items-list') do
              expect(page).to have_content(private_project_merge_request.title)
              expect(page).to have_css(".issue-token-state-icon")
            end

            expect(page).to have_content("mentioned in merge request #{private_project_merge_request.to_reference(public_project)}")
                       .and have_content(private_project_user.name)
          end
        end
      end
    end
  end

  context "when referencing to open merge request" do
    context "from private project" do
      context "from issue" do
        before do
          sign_in(private_project_user)

          visit(project_issue_path(private_project, private_project_issue))
          wait_for_requests

          add_note("##{public_project_merge_request.to_reference(private_project)}")
        end

        context "when user doesn't have access to private project" do
          before do
            sign_in(public_project_user)

            visit(project_merge_request_path(public_project, public_project_merge_request))
            wait_for_requests
          end

          it { expect(page).not_to have_css(".note") }
        end
      end

      context "from merge request" do
        before do
          sign_in(private_project_user)

          visit(project_merge_request_path(private_project, private_project_merge_request))
          wait_for_requests

          add_note("##{public_project_merge_request.to_reference(private_project)}")
        end

        context "when user doesn't have access to private project" do
          before do
            sign_in(public_project_user)

            visit(project_merge_request_path(public_project, public_project_merge_request))
            wait_for_requests
          end

          it "doesn't show any references" do
            expect(page).not_to have_text 'Related merge requests'
          end
        end

        context "when user has access to private project" do
          before do
            visit(project_merge_request_path(public_project, public_project_merge_request))
            wait_for_requests
          end

          it "shows references", :sidekiq_might_not_need_inline do
            expect(page).to have_content("mentioned in merge request #{private_project_merge_request.to_reference(public_project)}")
                       .and have_content(private_project_user.name)
          end
        end
      end
    end
  end
end
