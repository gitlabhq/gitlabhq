# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalProjectsFinder, feature_category: :groups_and_projects do
  let_it_be(:source_user)     { create(:user) }
  let_it_be(:current_user)    { create(:user) }
  let_it_be(:admin)           { create(:admin) }

  let(:finder)                { described_class.new(source_user) }
  let_it_be(:public_project) do
    create(:project, :public, namespace: source_user.namespace, last_activity_at: 1.year.ago, path: 'pblc')
  end

  let_it_be(:private_project_shared) do
    create(:project, :private, namespace: source_user.namespace, last_activity_at: 2.hours.ago, path: 'mepmep', developers: current_user)
  end

  let_it_be(:internal_project) do
    create(:project, :internal, namespace: source_user.namespace, last_activity_at: 3.hours.ago, path: 'C')
  end

  let_it_be(:private_project_self) do
    create(:project, :private, namespace: source_user.namespace, last_activity_at: 4.hours.ago, path: 'D')
  end

  describe 'without a current user' do
    subject { finder.execute }

    it { is_expected.to eq([public_project]) }
  end

  describe 'with a current user' do
    context 'normal user' do
      subject { finder.execute(current_user) }

      it { is_expected.to eq([private_project_shared, internal_project, public_project]) }
    end

    context 'external' do
      subject { finder.execute(current_user) }

      before do
        current_user.update!(external: true)
      end

      it { is_expected.to eq([private_project_shared, public_project]) }
    end

    context 'and searching with an admin user', :enable_admin_mode do
      subject { finder.execute(admin) }

      it { is_expected.to eq([private_project_shared, internal_project, private_project_self, public_project]) }
    end
  end
end
