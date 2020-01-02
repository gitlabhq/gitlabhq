# frozen_string_literal: true

require 'spec_helper'

describe SentNotificationsController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:private_project) { create(:project, :private) }
  let(:sent_notification) { create(:sent_notification, project: target_project, noteable: noteable, recipient: user) }

  let(:issue) do
    create(:issue, project: target_project) do |issue|
      issue.subscriptions.create(user: user, project: target_project, subscribed: true)
    end
  end

  let(:confidential_issue) do
    create(:issue, project: target_project, confidential: true) do |issue|
      issue.subscriptions.create(user: user, project: target_project, subscribed: true)
    end
  end

  let(:merge_request) do
    create(:merge_request, source_project: target_project, target_project: target_project) do |mr|
      mr.subscriptions.create(user: user, project: target_project, subscribed: true)
    end
  end

  let(:noteable) { issue }
  let(:target_project) { project }

  describe 'GET unsubscribe' do
    context 'when the user is not logged in' do
      context 'when the force param is passed' do
        before do
          get(:unsubscribe, params: { id: sent_notification.reply_key, force: true })
        end

        it 'unsubscribes the user' do
          expect(issue.subscribed?(user, project)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/)
        end

        it 'redirects to the login page' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when the force param is not passed' do
        render_views

        before do
          get(:unsubscribe, params: { id: sent_notification.reply_key })
        end

        shared_examples 'unsubscribing as anonymous' do |project_visibility|
          it 'does not unsubscribe the user' do
            expect(noteable.subscribed?(user, target_project)).to be_truthy
          end

          it 'does not set the flash message' do
            expect(controller).not_to set_flash[:notice]
          end

          it 'renders unsubscribe page' do
            expect(response.status).to eq(200)
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
    end

    context 'when the user is logged in' do
      before do
        sign_in(user)
      end

      context 'when the ID passed does not exist' do
        before do
          get(:unsubscribe, params: { id: sent_notification.reply_key.reverse })
        end

        it 'does not unsubscribe the user' do
          expect(issue.subscribed?(user, project)).to be_truthy
        end

        it 'does not set the flash message' do
          expect(controller).not_to set_flash[:notice]
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the force param is passed' do
        before do
          get(:unsubscribe, params: { id: sent_notification.reply_key, force: true })
        end

        it 'unsubscribes the user' do
          expect(issue.subscribed?(user, project)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/)
        end

        it 'redirects to the issue page' do
          expect(response)
            .to redirect_to(project_issue_path(project, issue))
        end
      end

      context 'when the force param is not passed' do
        let(:merge_request) do
          create(:merge_request, source_project: project, author: user) do |merge_request|
            merge_request.subscriptions.create(user: user, project: project, subscribed: true)
          end
        end
        let(:sent_notification) { create(:sent_notification, project: project, noteable: merge_request, recipient: user) }

        before do
          get(:unsubscribe, params: { id: sent_notification.reply_key })
        end

        it 'unsubscribes the user' do
          expect(merge_request.subscribed?(user, project)).to be_falsey
        end

        it 'sets the flash message' do
          expect(controller).to set_flash[:notice].to(/unsubscribed/)
        end

        it 'redirects to the merge request page' do
          expect(response)
            .to redirect_to(project_merge_request_path(project, merge_request))
        end
      end

      context 'when project is private' do
        context 'and user does not have access' do
          let(:noteable) { issue }
          let(:target_project) { private_project }

          before do
            get(:unsubscribe, params: { id: sent_notification.reply_key })
          end

          it 'unsubscribes user and redirects to root path' do
            expect(response).to redirect_to(root_path)
          end
        end

        context 'and user has access' do
          let(:noteable) { issue }
          let(:target_project) { private_project }

          before do
            private_project.add_developer(user)
            get(:unsubscribe, params: { id: sent_notification.reply_key })
          end

          it 'unsubscribes user and redirects to issue path' do
            expect(response).to redirect_to(project_issue_path(private_project, issue))
          end
        end
      end
    end
  end
end
