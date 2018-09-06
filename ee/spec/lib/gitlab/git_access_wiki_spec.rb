require 'spec_helper'

describe Gitlab::GitAccessWiki do
  let(:access) { described_class.new(user, project, 'web', authentication_abilities: authentication_abilities, redirected_path: redirected_path) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master'] }
  let(:redirected_path) { nil }
  let(:authentication_abilities) do
    [
        :read_project,
        :download_code,
        :push_code
    ]
  end

  context "when in a read-only GitLab instance" do
    subject { access.check('git-receive-pack', changes) }

    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    it 'denies push access' do
      project.add_maintainer(user)

      expect { subject }.to raise_unauthorized("You can't push code to a read-only GitLab instance.")
    end

    it 'denies push access with primary present' do
      error_message = "You can't push code to a read-only GitLab instance.
Please use the primary node URL instead: "\
"https://localhost:3000/gitlab/#{project.full_path}.wiki.git.
For more information: #{EE::Gitlab::GeoGitAccess::GEO_SERVER_DOCS_URL}"

      primary_node = create(:geo_node, :primary, url: 'https://localhost:3000/gitlab')
      allow(Gitlab::Geo).to receive(:primary).and_return(primary_node)
      allow(Gitlab::Geo).to receive(:secondary_with_primary?).and_return(true)

      project.add_maintainer(user)

      expect { subject }.to raise_unauthorized(error_message)
    end
  end

  context 'when wiki is disabled' do
    let(:user) { :geo }
    let(:project) { create(:project, :private, :wiki_repo, wiki_access_level: ProjectFeature::DISABLED) }
    let(:authentication_abilities) {  [:download_code] }

    subject { access.check('git-upload-pack', changes) }

    it 'allows code download for geo' do
      expect(subject).to be_truthy
    end
  end

  private

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end
end
