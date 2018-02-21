require 'spec_helper'

describe Gitlab::GitAccess do
  set(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:protocol) { 'web' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) { described_class.new(actor, project, protocol, authentication_abilities: authentication_abilities, redirected_path: redirected_path) }
  subject { access.check('git-receive-pack', '_any') }

  context "when in a read-only GitLab instance" do
    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    it 'denies push access' do
      project.add_master(user)

      expect { subject }.to raise_unauthorized("You can't push code to a read-only GitLab instance.")
    end

    it 'denies push access with primary present' do
      error_message = "You can't push code to a read-only GitLab instance."\
"\nPlease use the primary node URL instead: https://localhost:3000/gitlab/#{project.full_path}.git.
For more information: #{EE::Gitlab::GeoGitAccess::GEO_SERVER_DOCS_URL}"

      primary_node = create(:geo_node, :primary, url: 'https://localhost:3000/gitlab')
      allow(Gitlab::Geo).to receive(:primary).and_return(primary_node)
      allow(Gitlab::Geo).to receive(:secondary_with_primary?).and_return(true)

      project.add_master(user)

      expect { subject }.to raise_unauthorized(error_message)
    end
  end

  private

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end
end
