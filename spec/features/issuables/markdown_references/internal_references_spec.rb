# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Internal references", :js, feature_category: :markdown do
  let(:private_project_user) { private_project.first_owner }
  let(:private_project) { create(:project, :private, :repository) }
  let(:private_project_issue) { create(:issue, project: private_project) }
  let(:private_project_merge_request) { create(:merge_request, source_project: private_project) }
  let(:public_project_user) { public_project.first_owner }
  let(:public_project) { create(:project, :public, :repository) }
  let(:public_project_issue) { create(:issue, project: public_project) }
  let(:public_project_merge_request) { create(:merge_request, source_project: public_project) }

  # Create the referencing note directly instead of through the UI as
  # private_project_user. This avoids switching users within a single JS test,
  # which can fail with ActionController::InvalidAuthenticityToken when an
  # AJAX request from the previously loaded page (for example
  # POST /-/track_namespace_visits) is processed after the Warden session
  # resets and rotates the CSRF token. Calling create_cross_references!
  # mirrors what Notes::PostProcessService does when a note is created.
  def create_referencing_note(noteable, reference)
    create(
      :note,
      noteable: noteable,
      project: private_project,
      author: private_project_user,
      note: "##{reference.to_reference(private_project)}"
    ).create_cross_references!
  end

  context "when referencing to open issue" do
    context "from private project" do
      context "from issue" do
        before do
          create_referencing_note(private_project_issue, public_project_issue)
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
          create_referencing_note(private_project_merge_request, public_project_issue)
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
            sign_in(private_project_user)

            visit(project_issue_path(public_project, public_project_issue))
            wait_for_requests
          end

          it "shows references", :sidekiq_might_not_need_inline do
            within_testid('work-item-development') do
              expect(page).to have_text 'Development 1'
              expect(page).to have_link(private_project_merge_request.title)
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
          create_referencing_note(private_project_issue, public_project_merge_request)
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
          create_referencing_note(private_project_merge_request, public_project_merge_request)
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
            sign_in(private_project_user)

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
