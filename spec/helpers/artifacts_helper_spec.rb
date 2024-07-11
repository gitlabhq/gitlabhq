# frozen_string_literal: true

require "spec_helper"

RSpec.describe ArtifactsHelper, feature_category: :job_artifacts do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project) }

  describe '#artifacts_app_data' do
    before do
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :destroy_artifacts, project).and_return(false)
    end

    subject { helper.artifacts_app_data(project) }

    it 'returns expected data' do
      expect(subject).to include({
        project_path: project.full_path,
        project_id: project.id,
        job_artifacts_count_limit: 100
      })
    end

    describe 'can_destroy_artifacts' do
      it 'returns false without permission' do
        expect(subject[:can_destroy_artifacts]).to eq('false')
      end

      it 'returns true when user has permission' do
        allow(helper).to receive(:can?).with(user, :destroy_artifacts, project).and_return(true)

        expect(subject[:can_destroy_artifacts]).to eq('true')
      end
    end
  end
end
