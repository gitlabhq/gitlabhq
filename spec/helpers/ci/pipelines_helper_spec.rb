# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesHelper, feature_category: :continuous_integration do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project) }

  describe 'has_gitlab_ci?' do
    using RSpec::Parameterized::TableSyntax

    subject(:has_gitlab_ci?) { helper.has_gitlab_ci?(project) }

    let(:project) { double(:project, has_ci?: has_ci?, builds_enabled?: builds_enabled?) }

    where(:builds_enabled?, :has_ci?, :result) do
      true                | true    | true
      true                | false   | false
      false               | true    | false
      false               | false   | false
    end

    with_them do
      it { expect(has_gitlab_ci?).to eq(result) }
    end
  end

  describe '#pipelines_list_data' do
    subject(:data) { helper.pipelines_list_data(project, 'list_url') }

    before do
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'has the expected keys' do
      expect(subject.keys).to include(
        :endpoint,
        :project_id,
        :default_branch_name,
        :params,
        :artifacts_endpoint,
        :artifacts_endpoint_placeholder,
        :pipeline_schedules_path,
        :can_create_pipeline,
        :new_pipeline_path,
        :reset_cache_path,
        :has_gitlab_ci,
        :pipeline_editor_path,
        :suggested_ci_templates,
        :full_path,
        :visibility_pipeline_id_type,
        :show_jenkins_ci_prompt,
        :pipelines_analytics_path,
        :uses_external_config,
        :empty_state_illustration_path
      )
    end
  end

  describe '#visibility_pipeline_id_type' do
    subject { helper.visibility_pipeline_id_type }

    context 'when user is not signed in' do
      it 'shows default pipeline id type' do
        expect(subject).to eq('id')
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        user.user_preference.update!(visibility_pipeline_id_type: 'iid')
      end

      it 'shows user preference pipeline id type' do
        expect(subject).to eq('iid')
      end
    end
  end

  describe '#show_jenkins_ci_prompt' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.pipelines_list_data(project, 'list_url')[:show_jenkins_ci_prompt] }

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:repository) { project.repository }

    before do
      sign_in(user)
      project.send(add_role_method, user)

      allow(project).to receive(:has_ci_config_file?).and_return(has_gitlab_ci?)
      allow(repository).to receive(:jenkinsfile?).and_return(has_jenkinsfile?)
    end

    where(:add_role_method, :has_gitlab_ci?, :has_jenkinsfile?, :result) do
      # Test permissions
      :add_owner        | false   | true    | "true"
      :add_maintainer   | false   | true    | "true"
      :add_developer    | false   | true    | "true"
      :add_guest        | false   | true    | "false"

      # Test combination of presence of ci files
      :add_owner        | false   | false   | "false"
      :add_owner        | true    | true    | "false"
      :add_owner        | true    | false   | "false"
    end

    with_them do
      it { expect(subject).to eq(result) }
    end
  end

  describe '#new_pipeline_data' do
    subject(:data) { helper.new_pipeline_data(project) }

    it 'has the expected keys' do
      expect(subject.keys).to include(
        :project_id,
        :pipelines_path,
        :default_branch,
        :pipeline_editor_path,
        :can_view_pipeline_editor,
        :ref_param,
        :var_param,
        :file_param,
        :project_path,
        :project_refs_endpoint,
        :settings_link,
        :max_warnings,
        :user_role,
        :can_set_pipeline_variables
      )
    end

    describe 'user_role' do
      context 'when there is no current user' do
        it 'is nil' do
          expect(helper.new_pipeline_data(project)[:user_role]).to be_nil
        end
      end

      context 'when there is a current_user' do
        let_it_be(:user) { create(:user) }

        before_all do
          project.add_developer(user)
        end

        before do
          sign_in(user)
        end

        it "returns the human readable access level that the current user has in the pipeline's project" do
          expect(helper.new_pipeline_data(project)[:user_role]).to eq('Developer')
        end
      end
    end
  end

  describe '#uses_external_config?' do
    using RSpec::Parameterized::TableSyntax

    subject(:uses_external_config) { helper.uses_external_config?(project) }

    let(:project_config) { instance_double(Gitlab::Ci::ProjectConfig, external?: is_external) }

    before do
      allow(Gitlab::Ci::ProjectConfig).to receive(:new)
                                            .with(project: project, sha: nil)
                                            .and_return(project_config)
    end

    where(:is_external, :expected_result) do
      true | true
      false | false
    end

    with_them do
      it 'returns the expected result' do
        expect(uses_external_config).to be expected_result
      end
    end
  end
end
