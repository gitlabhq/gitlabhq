# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotificationsController, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:private_project) { create(:project, :private) }

  let(:email) { 'email@example.com' }

  let(:issue) do
    create(:issue, project: target_project, external_author: email) do |issue|
      issue.subscriptions.create!(user: user, project: target_project, subscribed: true)
      issue.issue_email_participants.create!(email: email)
    end
  end

  let(:confidential_issue) do
    create(:issue, project: target_project, confidential: true) do |issue|
      issue.subscriptions.create!(user: user, project: target_project, subscribed: true)
    end
  end

  let(:merge_request) do
    create(:merge_request, source_project: target_project, target_project: target_project) do |mr|
      mr.subscriptions.create!(user: user, project: target_project, subscribed: true)
    end
  end

  let(:noteable) { issue }
  let(:target_project) { project }

  let(:sent_notification) do
    create(:sent_notification, project: target_project, noteable: noteable, recipient: user)
  end

  let(:id) { sent_notification.reply_key }
  let(:perform_request) { unsubscribe }

  def force_unsubscribe
    get(:unsubscribe, params: { id: id, force: true })
  end

  def unsubscribe
    get(:unsubscribe, params: { id: id })
  end

  def post_unsubscribe
    post(:unsubscribe, params: { id: id })
  end

  shared_examples 'returns 404' do
    it 'does not set the flash message' do
      expect(controller).not_to set_flash[:notice]
    end

    it 'returns a 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'validates parameters and records' do
    context 'when the ID passed does not exist' do
      let(:id) { sent_notification.reply_key.reverse }

      before do
        perform_request
      end

      it_behaves_like 'returns 404'
    end

    context 'when the noteable associated to the notification has been deleted' do
      before do
        sent_notification.noteable.destroy!

        perform_request
      end

      it_behaves_like 'returns 404'
    end
  end

  shared_examples 'unsubscribes a user' do
    before do
      perform_request
    end

    it 'unsubscribes the user' do
      expect(issue.subscribed?(user, project)).to be_falsey
    end

    it 'does not delete the issue email participant for non-service-desk issue' do
      expect { force_unsubscribe }.not_to change { issue.issue_email_participants.count }
    end

    it 'sets the flash message' do
      expect(controller).to set_flash[:notice].to(/unsubscribed/)
    end
  end

  shared_examples 'unsubscribes an external participant' do
    context 'when support bot is the notification recipient' do
      let(:sent_notification) do
        create(:sent_notification,
          project: target_project, noteable: noteable, recipient: Users::Internal.support_bot)
      end

      it 'deletes the external author on the issue' do
        expect { perform_request }.to change { issue.issue_email_participants.count }.by(-1)
      end

      context 'when sent_notification contains issue_email_participant' do
        let!(:other_issue_email_participant) do
          create(:issue_email_participant, issue: issue, email: 'other@example.com')
        end

        let(:sent_notification) do
          create(:sent_notification,
            project: target_project,
            noteable: noteable,
            recipient: Users::Internal.support_bot,
            issue_email_participant: other_issue_email_participant
          )
        end

        it 'deletes the connected issue email participant' do
          expect { perform_request }.to change { issue.issue_email_participants.count }.by(-1)
          # Ensure external author is still present
          expect(issue.email_participants_emails).to contain_exactly(email)
        end
      end

      context 'when noteable is not an issue' do
        let(:noteable) { merge_request }

        it 'does not delete the external author on the issue' do
          expect { perform_request }.not_to change { issue.issue_email_participants.count }
        end
      end
    end
  end

  describe 'GET unsubscribe' do
    context 'when the user is not logged in' do
      context 'when the force param is passed' do
        let(:perform_request) { force_unsubscribe }

        it_behaves_like 'unsubscribes a user'
        it_behaves_like 'unsubscribes an external participant'

        it 'redirects to the login page' do
          force_unsubscribe
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when the force param is not passed' do
        render_views

        before do
          unsubscribe
        end

        shared_examples 'unsubscribing as anonymous' do |project_visibility|
          it 'does not unsubscribe the user' do
            expect(noteable.subscribed?(user, target_project)).to be_truthy
          end

          it 'does not set the flash message' do
            expect(controller).not_to set_flash[:notice]
          end

          it 'renders unsubscribe page' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template :unsubscribe
          end

          if project_visibility == :private
            it 'does not show project name or path' do
              expect(response.body).not_to include(noteable.project.name)
              expect(response.body).not_to include(noteable.project.full_name)
            end
          else
            it 'shows project name or path' do
              expect(response.body).to include(noteable.project.name)
              expect(response.body).to include(noteable.project.full_name)
            end
          end
        end

        context 'when project is public' do
          context 'when unsubscribing from issue' do
            let(:noteable) { issue }

            it 'shows issue title' do
              expect(response.body).to include(issue.title)
            end

            it 'does not delete the issue email participant' do
              expect { unsubscribe }.not_to change { issue.issue_email_participants.count }
            end

            it_behaves_like 'unsubscribing as anonymous', :public
          end

          context 'when unsubscribing from confidential issue' do
            let(:noteable) { confidential_issue }

            it 'does not show issue title' do
              expect(response.body).not_to include(confidential_issue.title)
              expect(response.body).to include(confidential_issue.to_reference)
            end

            it_behaves_like 'unsubscribing as anonymous', :public
          end

          context 'when unsubscribing from merge request' do
            let(:noteable) { merge_request }

            it 'shows merge request title' do
              expect(response.body).to include(merge_request.title)
            end

            it 'shows project name or path' do
              expect(response.body).to include(issue.project.name)
              expect(response.body).to include(issue.project.full_name)
            end

            it_behaves_like 'unsubscribing as anonymous', :public
          end
        end

        context 'when project is not public' do
          let(:target_project) { private_project }

          context 'when unsubscribing from issue' do
            let(:noteable) { issue }

            it 'does not show issue title' do
              expect(response.body).not_to include(issue.title)
            end

            it_behaves_like 'unsubscribing as anonymous', :private
          end

          context 'when unsubscribing from confidential issue' do
            let(:noteable) { confidential_issue }

            it 'does not show issue title' do
              expect(response.body).not_to include(confidential_issue.title)
              expect(response.body).to include(confidential_issue.to_reference)
            end

            it_behaves_like 'unsubscribing as anonymous', :private
          end

          context 'when unsubscribing from merge request' do
            let(:noteable) { merge_request }

            it 'dos not show merge request title' do
              expect(response.body).not_to include(merge_request.title)
            end

            it_behaves_like 'unsubscribing as anonymous', :private
          end
        end
      end

      it_behaves_like 'validates parameters and records'
    end

    context 'when the user is logged in' do
      before do
        sign_in(user)
      end

      it_behaves_like 'validates parameters and records'
      it_behaves_like 'unsubscribes an external participant'

      context 'when the force param is passed' do
        let(:perform_request) { force_unsubscribe }

        it_behaves_like 'unsubscribes a user'

        it 'redirects to the issue page' do
          force_unsubscribe
          expect(response).to redirect_to(project_issue_path(project, issue))
        end
      end

      context 'when the force param is not passed' do
        let(:merge_request) do
          create(:merge_request, source_project: project, author: user) do |merge_request|
            merge_request.subscriptions.create!(user: user, project: project, subscribed: true)
          end
        end

        let(:sent_notification) do
          create(:sent_notification, project: project, noteable: merge_request, recipient: user)
        end

        before do
          unsubscribe
        end

        it 'unsubscribes the user' do
          expect(merge_request.subscribed?(user, project)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/)
        end

        it 'redirects to the merge request page' do
          expect(response).to redirect_to(project_merge_request_path(project, merge_request))
        end

        context 'when unsubscribing from design' do
          let(:design) do
            # reload necessary as namespace_id is set in a DB trigger
            create(:design, issue: issue) do |design|
              design.subscriptions.create!(user: user, project: project, subscribed: true)
            end.reload
          end

          let(:sent_notification) do
            create(:sent_notification, project: project, noteable: design, recipient: user)
          end

          before do
            unsubscribe
          end

          it 'unsubscribes the user' do
            expect(design.subscribed?(user, project)).to be_falsey
          end
        end
      end

      context 'when project is private' do
        context 'and user does not have access' do
          let(:noteable) { issue }
          let(:target_project) { private_project }

          before do
            unsubscribe
          end

          it 'unsubscribes user and redirects to root path' do
            expect(response).to redirect_to(root_path)
          end
        end

        context 'and user has access' do
          let(:noteable) { issue }
          let(:target_project) { private_project }

          before_all do
            private_project.add_developer(user)
          end

          before do
            unsubscribe
          end

          it 'unsubscribes user and redirects to issue path' do
            expect(response).to redirect_to(project_issue_path(private_project, issue))
          end

          it 'does not delete the issue email participant for non-service-desk issue' do
            expect { unsubscribe }.not_to change { issue.issue_email_participants.count }
          end
        end
      end
    end
  end

  describe 'POST unsubscribe' do
    let(:perform_request) { post_unsubscribe }

    # Ensure we don't verify CSRF token
    around do |example|
      ForgeryProtection.with_forgery_protection { example.run }
    end

    it_behaves_like 'validates parameters and records'

    context 'when the user is not logged in' do
      it_behaves_like 'unsubscribes a user'
      it_behaves_like 'unsubscribes an external participant'

      it 'redirects to the login page' do
        post_unsubscribe
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when the user is logged in' do
      before do
        sign_in(user)
      end

      it_behaves_like 'unsubscribes a user'

      it 'redirects to the issue page' do
        post_unsubscribe
        expect(response).to redirect_to(project_issue_path(project, issue))
      end
    end
  end
end
