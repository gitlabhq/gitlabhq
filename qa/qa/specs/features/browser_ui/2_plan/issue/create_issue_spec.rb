# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, feature_flag: { name: 'vue_issues_list', scope: :group } do
    describe 'Issue creation' do
      let(:project) { Resource::Project.fabricate_via_api! }
      let(:closed_issue) { Resource::Issue.fabricate_via_api! { |issue| issue.project = project } }

      before do
        Runtime::Feature.enable(:vue_issues_list, group: project.group)

        Flow::Login.sign_in
      end

      it(
        'creates an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347989',
        except: { subdomain: 'pre' }
      ) do
        issue = Resource::Issue.fabricate_via_browser_ui! { |issue| issue.project = project }

        Page::Project::Menu.perform(&:click_issues)

        # TODO: Remove this method when the `Runtime::Feature.enable` method call is removed
        Page::Project::Issue::Index.perform(&:wait_for_vue_issues_list_ff)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_issue(issue)
        end
      end

      it(
        'closes an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347967',
        except: { subdomain: 'pre' }
      ) do
        closed_issue.visit!

        Page::Project::Issue::Show.perform do |issue_page|
          issue_page.click_close_issue_button

          expect(issue_page).to have_reopen_issue_button
        end

        Page::Project::Menu.perform(&:click_issues)

        # TODO: Remove this method when the `Runtime::Feature.enable` method call is removed
        Page::Project::Issue::Index.perform(&:wait_for_vue_issues_list_ff)

        Page::Project::Issue::Index.perform do |index|
          expect(index).not_to have_issue(closed_issue)

          index.click_closed_issues_tab

          expect(index).to have_issue(closed_issue)
        end
      end

      context 'when using attachments in comments', :object_storage do
        let(:png_file_name) { 'testfile.png' }
        let(:file_to_attach) do
          File.absolute_path(File.join('qa', 'fixtures', 'designs', png_file_name))
        end

        before do
          Resource::Issue.fabricate_via_api! { |issue| issue.project = project }.visit!
        end

        # The following example is excluded from running in `review-qa-smoke` job
        # as it proved to be flaky when running against Review App
        # See https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/11568#note_621999351
        it 'comments on an issue with an attachment', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347946', except: { subdomain: 'pre', job: 'review-qa-smoke' } do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached image for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{png_file_name}']")).to be_visible
          end
        end
      end
    end
  end
end
