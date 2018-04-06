require 'spec_helper'

describe CiCd::SetupProject do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user, import_type: 'github', import_url: 'http://foo.com') }

  subject do
    described_class.new(project, project.creator)
  end

  before do
    allow(CiCd::GithubSetupService).to receive_message_chain(:new, :execute)
  end

  it 'sets up pull mirroring on the project' do
    subject.execute

    expect(project.mirror).to be_truthy
    expect(project.mirror_trigger_builds).to be_truthy
    expect(project.mirror_user_id).to eq(user.id)
  end

  it 'disables some features' do
    subject.execute

    project_feature = project.project_feature

    expect(project_feature).not_to be_issues_enabled
    expect(project_feature).not_to be_merge_requests_enabled
    expect(project_feature).not_to be_wiki_enabled
    expect(project_feature.snippets_access_level).to eq(ProjectFeature::DISABLED)
  end

  context 'when import_url is blank' do
    before do
      project.update_attribute(:import_url, nil)
    end

    it "doesn't update the project" do
      expect(project).not_to receive(:update_project)
      expect(project).not_to receive(:disable_project_features)

      subject.execute
    end
  end

  describe '#setup_external_service' do
    context 'when import_type is missing' do
      it "does not invoke the service class" do
        project.update_attribute(:import_type, nil)

        expect(CiCd::GithubSetupService).not_to receive(:new)

        subject.execute
      end
    end

    context "when importer doesn't require extra setup" do
      it "does not invoke the service class" do
        allow(Gitlab::GithubImport::ParallelImporter).to receive(:requires_ci_cd_setup?).and_return(false)

        expect(CiCd::GithubSetupService).not_to receive(:new)

        subject.execute
      end
    end

    context 'whem importer requires extra setup' do
      it 'invokes the custom service class' do
        expect(CiCd::GithubSetupService).to receive_message_chain(:new, :execute)

        subject.execute
      end
    end
  end
end
