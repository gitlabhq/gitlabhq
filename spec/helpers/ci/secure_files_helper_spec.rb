# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFilesHelper, feature_category: :mobile_devops do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:anonymous) { create(:user) }
  let_it_be(:unconfirmed) { create(:user, :unconfirmed) }
  let_it_be(:project) do
    create(:project, creator_id: maintainer.id, maintainers: maintainer, developers: developer, guests: guest)
  end

  subject { helper.show_secure_files_setting(project, user) }

  describe '#show_secure_files_setting' do
    context 'when disabled at the instance level' do
      before do
        stub_config(ci_secure_files: { enabled: false })
      end

      let(:user) { maintainer }

      it { is_expected.to be false }
    end

    context 'authenticated user with admin permissions' do
      let(:user) { maintainer }

      it { is_expected.to be true }
    end

    context 'authenticated user with read permissions' do
      let(:user) { developer }

      it { is_expected.to be true }
    end

    context 'authenticated user with guest permissions' do
      let(:user) { guest }

      it { is_expected.to be false }
    end

    context 'authenticated user with no permissions' do
      let(:user) { anonymous }

      it { is_expected.to be false }
    end

    context 'unconfirmed user' do
      let(:user) { unconfirmed }

      it { is_expected.to be false }
    end

    context 'unauthenticated user' do
      let(:user) { nil }

      it { is_expected.to be false }
    end
  end
end
