# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ExperienceLevelsController do
  let_it_be(:namespace) { create(:group, path: 'group-path' ) }
  let_it_be(:user) { create(:user) }

  let(:params) { { namespace_path: namespace.to_param } }

  describe 'GET #show' do
    subject { get :show, params: params }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        stub_experiment_for_user(onboarding_issues: true)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }
      it { is_expected.to render_template('layouts/devise_experimental_onboarding_issues') }
      it { is_expected.to render_template(:show) }

      context 'when not part of the onboarding issues experiment' do
        before do
          stub_experiment_for_user(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'PUT/PATCH #update' do
    subject { patch :update, params: params }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        stub_experiment_for_user(onboarding_issues: true)
      end

      context 'when not part of the onboarding issues experiment' do
        before do
          stub_experiment_for_user(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when user is successfully updated' do
        context 'when no experience_level is sent' do
          before do
            user.user_preference.update_attribute(:experience_level, :novice)
          end

          it 'will unset the user’s experience level' do
            expect { subject }.to change { user.reload.experience_level }.to(nil)
          end
        end

        context 'when an expected experience level is sent' do
          let(:params) { super().merge(experience_level: :novice) }

          it 'sets the user’s experience level' do
            expect { subject }.to change { user.reload.experience_level }.from(nil).to('novice')
          end
        end

        context 'when an unexpected experience level is sent' do
          let(:params) { super().merge(experience_level: :nonexistent) }

          it 'raises an exception' do
            expect { subject }.to raise_error(ArgumentError, "'nonexistent' is not a valid experience_level")
          end
        end

        describe 'redirection' do
          let(:project) { build(:project, namespace: namespace, creator: user, path: 'project-path') }
          let(:issues_board) { build(:board, id: 123, project: project) }

          before do
            stub_experiment_for_user(
              onboarding_issues: true,
              default_to_issues_board: default_to_issues_board_xp?
            )
            allow_next_instance_of(LearnGitlab) do |learn_gitlab|
              allow(learn_gitlab).to receive(:available?).and_return(learn_gitlab_available?)
              allow(learn_gitlab).to receive(:project).and_return(project)
              allow(learn_gitlab).to receive(:board).and_return(issues_board)
            end
          end

          context 'when namespace_path param is missing' do
            let(:params) { super().merge(namespace_path: nil) }

            where(
              default_to_issues_board_xp?: [true, false],
              learn_gitlab_available?: [true, false]
            )

            with_them do
              it { is_expected.to redirect_to('/') }
            end
          end

          context 'when we have a namespace_path param' do
            using RSpec::Parameterized::TableSyntax

            where(:default_to_issues_board_xp?, :learn_gitlab_available?, :path) do
              true  | true  | '/group-path/project-path/-/boards/123'
              true  | false | '/group-path'
              false | true  | '/group-path'
              false | false | '/group-path'
            end

            with_them do
              it { is_expected.to redirect_to(path) }
            end
          end
        end

        describe 'applying the chosen level' do
          context 'when a "Learn GitLab" project is available' do
            before do
              allow_next_instance_of(LearnGitlab) do |learn_gitlab|
                allow(learn_gitlab).to receive(:available?).and_return(true)
                allow(learn_gitlab).to receive(:label).and_return(double(id: 1))
              end
            end

            context 'when novice' do
              let(:params) { super().merge(experience_level: :novice) }

              it 'adds a BoardLabel' do
                expect_next_instance_of(Boards::UpdateService) do |service|
                  expect(service).to receive(:execute)
                end

                subject
              end
            end

            context 'when experienced' do
              let(:params) { super().merge(experience_level: :experienced) }

              it 'does not add a BoardLabel' do
                expect(Boards::UpdateService).not_to receive(:new)

                subject
              end
            end
          end

          context 'when no "Learn GitLab" project exists' do
            let(:params) { super().merge(experience_level: :novice) }

            before do
              allow_next_instance_of(LearnGitlab) do |learn_gitlab|
                allow(learn_gitlab).to receive(:available?).and_return(false)
              end
            end

            it 'does not add a BoardLabel' do
              expect(Boards::UpdateService).not_to receive(:new)

              subject
            end
          end
        end
      end

      context 'when user update fails' do
        before do
          allow_any_instance_of(User).to receive(:save).and_return(false)
        end

        it { is_expected.to render_template(:show) }
      end
    end
  end
end
