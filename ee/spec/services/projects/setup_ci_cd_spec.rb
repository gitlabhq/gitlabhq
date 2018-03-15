require 'spec_helper'

describe Projects::SetupCiCd do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user, import_url: 'http://foo.com') }

  subject do
    described_class.new(project, project.creator)
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
end
