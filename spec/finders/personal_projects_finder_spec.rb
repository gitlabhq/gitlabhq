# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalProjectsFinder do
  let_it_be(:source_user)     { create(:user) }
  let_it_be(:current_user)    { create(:user) }
  let_it_be(:admin)           { create(:admin) }

  let(:finder)                { described_class.new(source_user) }
  let!(:public_project) do
    create(:project, :public, namespace: source_user.namespace, updated_at: 1.hour.ago, path: 'pblc')
  end

  let!(:private_project_shared) do
    create(:project, :private, namespace: source_user.namespace, updated_at: 3.hours.ago, path: 'mepmep')
  end

  let!(:internal_project) do
    create(:project, :internal, namespace: source_user.namespace, updated_at: 2.hours.ago, path: 'C')
  end

  let!(:private_project_self) do
    create(:project, :private, namespace: source_user.namespace, updated_at: 3.hours.ago, path: 'D')
  end

  before do
    private_project_shared.add_developer(current_user)
  end

  describe 'without a current user' do
    subject { finder.execute }

    it { is_expected.to eq([public_project]) }
  end

  describe 'with a current user' do
    context 'normal user' do
      subject { finder.execute(current_user) }

      it { is_expected.to match_array([public_project, internal_project, private_project_shared]) }
    end

    context 'external' do
      subject { finder.execute(current_user) }

      before do
        current_user.update!(external: true)
      end

      it { is_expected.to match_array([public_project, private_project_shared]) }
    end

    context 'and searching with an admin user', :enable_admin_mode do
      subject { finder.execute(admin) }

      it { is_expected.to match_array([public_project, internal_project, private_project_self, private_project_shared]) }
    end
  end
end
