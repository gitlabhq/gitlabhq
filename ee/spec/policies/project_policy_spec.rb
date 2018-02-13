require 'spec_helper'

describe ProjectPolicy do
  set(:owner) { create(:user) }
  set(:admin) { create(:admin) }
  set(:developer) { create(:user) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  before do
    project.add_developer(developer)
  end

  context 'admin_mirror' do
    context 'with remote mirror setting enabled' do
      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with developer' do
        subject do
          described_class.new(developer, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirror setting disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature disabled' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature enabled' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end
    end
  end
end
