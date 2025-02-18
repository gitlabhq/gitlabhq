# frozen_string_literal: true

module QA
  describe 'Manage', product_group: :import_and_integrate do
    describe 'Gitlab migration',
      feature_flag: {
        name: [:importer_user_mapping, :bulk_import_importer_user_mapping],
        scope: :global
      } do
      include_context "with gitlab project migration"

      context 'with user contribution reassignment', :orchestrated, :import_with_smtp do
        let(:mail_hog) { Vendor::MailHog::API.new }
        let(:reassignment_email_subject) { "Reassignments in #{target_sandbox.name} waiting for review" }
        let!(:source_project_with_readme) { true }

        let!(:source_issue) do
          create(:issue, project: source_project, labels: %w[label_one label_two],
            api_client: source_admin_api_client)
        end

        let!(:source_issue_comment) { source_issue.add_comment(body: 'This is a test issue comment!') }

        let!(:source_mr) do
          create(:merge_request, project: source_project, api_client: source_admin_api_client)
        end

        let!(:source_mr_comment) { source_mr.add_comment(body: 'This is a test mr comment!') }

        let(:imported_issue) { imported_project.issues.first }

        let(:imported_merge_request) { imported_project.merge_requests.first }

        let(:placeholder_user) do
          build(:user,
            name: "Placeholder #{source_admin_user.name}")
        end

        before do
          Runtime::Feature.enable(:importer_user_mapping)
          Runtime::Feature.enable(:bulk_import_importer_user_mapping)

          Flow::Login.sign_in(as: user)
        end

        it 'reassigns placeholder users in issues and merge requests after reassignment',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/504548' do
          expect_project_import_finished_successfully

          page.visit imported_issue[:web_url]

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).to have_author(placeholder_user.name)
            expect(issue).to have_comment_author(placeholder_user.name)
          end

          page.visit imported_merge_request[:web_url]

          Page::MergeRequest::Show.perform do |merge_request|
            expect(merge_request).to have_author(placeholder_user.name)
            expect(merge_request).to have_comment_author(placeholder_user.name)
          end

          target_sandbox.visit!
          Page::Group::Menu.perform(&:go_to_members)
          Page::Group::Members.perform do |members_page|
            aggregate_failures do
              expect(members_page).to have_tab_count("Placeholders", 1)

              members_page.click_tab("Placeholders")

              expect(members_page).to have_tab_count("Awaiting reassignment", 1)
              expect(members_page).to have_tab_count("Reassigned", 0)
              expect(members_page).to have_reassignment_status("placeholders-table-unassigned", "Not started")

              members_page.reassign_placeholder_user("placeholders-table-unassigned", user.username)

              expect(members_page).to have_reassignment_status("placeholders-table-unassigned", "Pending approval")
            end
          end

          expect { email_subjects }.to eventually_include(reassignment_email_subject).within(max_duration: 300)

          reassignment_url = fetch_reassignment_url(reassignment_email_subject)
          Runtime::Logger.debug("Visiting reassignment url #{reassignment_url}")
          page.visit reassignment_url
          Page::Import::ReviewReassignment.perform(&:click_approve_reassignment)

          target_sandbox.visit!
          Page::Group::Menu.perform(&:go_to_members)
          Page::Group::Members.perform do |members_page|
            members_page.click_tab("Placeholders")
            members_page.wait_until_reassignment_completed!
            members_page.click_tab("Reassigned")

            aggregate_failures do
              expect(members_page).to have_reassignment_status("placeholders-table-reassigned", "Success")
              expect(members_page).to have_reassigned_user("placeholders-table-reassigned", user.username)
              expect(members_page).to have_tab_count("Reassigned", 1)
            end
          end

          page.visit imported_issue[:web_url]

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).to have_author(user.name)
            expect(issue).to have_comment_author(user.name)
          end

          page.visit imported_merge_request[:web_url]

          Page::MergeRequest::Show.perform do |merge_request|
            expect(merge_request).to have_author(user.name)
            expect(merge_request).to have_comment_author(user.name)
          end
        end
      end

      private

      def mail_hog_messages
        Runtime::Logger.debug('Fetching email...')

        messages = mail_hog.fetch_messages
        logs = messages.map { |m| "#{m.to}: #{m.subject}" }

        Runtime::Logger.debug("MailHog Logs: #{logs.join("\n")}")

        messages
      end

      def email_subjects
        mail_hog_messages.map(&:subject)
      end

      def find_email(reassignment_email_subject)
        Runtime::Logger.debug("Looking for email with subject containing: #{reassignment_email_subject}")
        mail_hog_messages.find { |m| m.subject&.include?(reassignment_email_subject) }
      end

      def fetch_reassignment_url(reassignment_email_subject)
        pattern = %r{https?://[\S]+/import/source_users/[-A-Z0-9]+}i
        email = find_email(reassignment_email_subject)
        email.body&.match(pattern).to_s
      end
    end
  end
end
