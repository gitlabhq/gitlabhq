require 'spec_helper'

describe SnippetsFinder do
  include ExternalAuthorizationServiceHelpers

  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:project_snippet, project: project) }
    let(:project_params) { { project: project } }
  end

  context 'external authorization service enabled' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let!(:snippet) { create(:project_snippet, :public, project: project) }

    before do
      project.add_master(user)
    end

    it 'includes the result if the external service allows access' do
      external_service_allow_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to contain_exactly(snippet)
    end

    it 'does not include any results if the external service denies access' do
      external_service_deny_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to be_empty
    end
  end
end
