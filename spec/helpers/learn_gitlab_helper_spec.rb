# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlabHelper, feature_category: :onboarding do
  include AfterNextHelpers
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: Onboarding::LearnGitlab::PROJECT_NAME, namespace: user.namespace) }
  let_it_be(:namespace) { project.namespace }

  before do
    allow_next_instance_of(Onboarding::LearnGitlab) do |learn_gitlab|
      allow(learn_gitlab).to receive(:project).and_return(project)
    end

    Onboarding::Progress.onboard(namespace)
    Onboarding::Progress.register(namespace, :git_write)
  end

  describe '#learn_gitlab_enabled?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    let(:params) { { namespace_id: project.namespace.to_param, project_id: project } }

    subject { helper.learn_gitlab_enabled?(project) }

    where(:onboarding, :learn_gitlab_available, :result) do
      true        | true                  | true
      true        | false                 | false
      false       | true                  | false
    end

    with_them do
      before do
        allow(Onboarding::Progress).to receive(:onboarding?).with(project.namespace).and_return(onboarding)
        allow_next(Onboarding::LearnGitlab, user).to receive(:available?).and_return(learn_gitlab_available)
      end

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'when not signed in' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#learn_gitlab_data' do
    subject(:learn_gitlab_data) { helper.learn_gitlab_data(project) }

    let(:onboarding_actions_data) { Gitlab::Json.parse(learn_gitlab_data[:actions]).deep_symbolize_keys }
    let(:onboarding_sections_data) { Gitlab::Json.parse(learn_gitlab_data[:sections]).deep_symbolize_keys }
    let(:onboarding_project_data) { Gitlab::Json.parse(learn_gitlab_data[:project]).deep_symbolize_keys }

    shared_examples 'has all data' do
      it 'has all actions' do
        expected_keys = [
          :issue_created,
          :git_write,
          :pipeline_created,
          :merge_request_created,
          :user_added,
          :trial_started,
          :required_mr_approvals_enabled,
          :code_owners_enabled,
          :security_scan_enabled
        ]

        expect(onboarding_actions_data.keys).to contain_exactly(*expected_keys)
      end

      it 'has all section data', :aggregate_failures do
        expect(onboarding_sections_data.keys).to contain_exactly(:deploy, :plan, :workspace)
        expect(onboarding_sections_data.values.map(&:keys)).to match_array([[:svg]] * 3)
      end

      it 'has all project data', :aggregate_failures do
        expect(onboarding_project_data.keys).to contain_exactly(:name)
        expect(onboarding_project_data.values).to match_array([project.name])
      end
    end

    it_behaves_like 'has all data'

    it 'sets correct completion statuses' do
      expect(onboarding_actions_data).to match({
                                                 issue_created: a_hash_including(completed: false),
                                                 git_write: a_hash_including(completed: true),
                                                 pipeline_created: a_hash_including(completed: false),
                                                 merge_request_created: a_hash_including(completed: false),
                                                 user_added: a_hash_including(completed: false),
                                                 trial_started: a_hash_including(completed: false),
                                                 required_mr_approvals_enabled: a_hash_including(completed: false),
                                                 code_owners_enabled: a_hash_including(completed: false),
                                                 security_scan_enabled: a_hash_including(completed: false)
                                               })
    end

    describe 'security_actions_continuous_onboarding experiment' do
      let(:base_paths) do
        {
          trial_started: a_hash_including(url: %r{/learn_gitlab/-/issues/2\z}),
          pipeline_created: a_hash_including(url: %r{/learn_gitlab/-/issues/7\z}),
          code_owners_enabled: a_hash_including(url: %r{/learn_gitlab/-/issues/10\z}),
          required_mr_approvals_enabled: a_hash_including(url: %r{/learn_gitlab/-/issues/11\z}),
          issue_created: a_hash_including(url: %r{/learn_gitlab/-/issues\z}),
          git_write: a_hash_including(url: %r{/learn_gitlab\z}),
          user_added: a_hash_including(url: %r{/learn_gitlab/-/project_members\z}),
          merge_request_created: a_hash_including(url: %r{/learn_gitlab/-/merge_requests\z})
        }
      end

      context 'when control' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :control)
        end

        it 'sets correct paths' do
          expect(onboarding_actions_data).to match(
            base_paths.merge(
              security_scan_enabled: a_hash_including(
                url: %r{/learn_gitlab/-/security/configuration\z}
              )
            )
          )
        end
      end

      context 'when candidate' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :candidate)
        end

        it 'sets correct paths' do
          expect(onboarding_actions_data).to match(
            base_paths.merge(
              license_scanning_run: a_hash_including(
                url: described_class::LICENSE_SCANNING_RUN_URL
              ),
              secure_dependency_scanning_run: a_hash_including(
                url: project_security_configuration_path(project, anchor: 'dependency-scanning')
              ),
              secure_dast_run: a_hash_including(
                url: project_security_configuration_path(project, anchor: 'dast')
              )
            )
          )
        end
      end
    end
  end
end
