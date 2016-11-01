require 'rails_helper'

describe SentNotificationsController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:sent_notification) { create(:sent_notification, noteable: issue, recipient: user) }

  let(:issue) do
    create(:issue, project: project, author: user) do |issue|
      issue.subscriptions.create(user: user, project: project, subscribed: true)
    end
  end

  describe 'GET unsubscribe' do
    context 'when the user is not logged in' do
      context 'when the force param is passed' do
        before { get(:unsubscribe, id: sent_notification.reply_key, force: true) }

        it 'unsubscribes the user' do
          expect(issue.subscribed?(user)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/).now
        end

        it 'redirects to the login page' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when the force param is not passed' do
        before { get(:unsubscribe, id: sent_notification.reply_key) }

        it 'does not unsubscribe the user' do
          expect(issue.subscribed?(user)).to be_truthy
        end

        it 'does not set the flash message' do
          expect(controller).not_to set_flash[:notice]
        end

        it 'redirects to the login page' do
          expect(response).to render_template :unsubscribe
        end
      end
    end

    context 'when the user is logged in' do
      before { sign_in(user) }

      context 'when the ID passed does not exist' do
        before { get(:unsubscribe, id: sent_notification.reply_key.reverse) }

        it 'does not unsubscribe the user' do
          expect(issue.subscribed?(user)).to be_truthy
        end

        it 'does not set the flash message' do
          expect(controller).not_to set_flash[:notice]
        end

        it 'returns a 404' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the force param is passed' do
        before { get(:unsubscribe, id: sent_notification.reply_key, force: true) }

        it 'unsubscribes the user' do
          expect(issue.subscribed?(user)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/).now
        end

        it 'redirects to the issue page' do
          expect(response).
            to redirect_to(namespace_project_issue_path(project.namespace, project, issue))
        end
      end

      context 'when the force param is not passed' do
        let(:merge_request) do
          create(:merge_request, source_project: project, author: user) do |merge_request|
            merge_request.subscriptions.create(user: user, project: project, subscribed: true)
          end
        end
        let(:sent_notification) { create(:sent_notification, noteable: merge_request, recipient: user) }
        before { get(:unsubscribe, id: sent_notification.reply_key) }

        it 'unsubscribes the user' do
          expect(merge_request.subscribed?(user)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/).now
        end

        it 'redirects to the merge request page' do
          expect(response).
            to redirect_to(namespace_project_merge_request_path(project.namespace, project, merge_request))
        end
      end
    end
  end
end
