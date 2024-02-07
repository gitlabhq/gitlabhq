# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesHelper, feature_category: :continuous_integration do
  include Devise::Test::ControllerHelpers

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
    let_it_be(:project) { create(:project) }

    subject(:data) { helper.pipelines_list_data(project, 'list_url') }

    before do
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'has the expected keys' do
      expect(subject.keys).to match_array([:endpoint,
                                           :project_id,
                                           :default_branch_name,
                                           :params,
                                           :artifacts_endpoint,
                                           :artifacts_endpoint_placeholder,
                                           :pipeline_schedules_path,
                                           :can_create_pipeline,
                                           :new_pipeline_path,
                                           :ci_lint_path,
                                           :reset_cache_path,
                                           :has_gitlab_ci,
                                           :pipeline_editor_path,
                                           :suggested_ci_templates,
                                           :full_path,
                                           :visibility_pipeline_id_type,
                                           :show_jenkins_ci_prompt])
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
end
