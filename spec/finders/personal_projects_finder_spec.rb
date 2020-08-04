# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalProjectsFinder do
  let(:source_user)     { create(:user) }
  let(:current_user)    { create(:user) }
  let(:finder)          { described_class.new(source_user) }
  let!(:public_project) do
    create(:project, :public, namespace: source_user.namespace, updated_at: 1.hour.ago)
  end

  let!(:private_project) do
    create(:project, :private, namespace: source_user.namespace, updated_at: 3.hours.ago, path: 'mepmep')
  end

  let!(:internal_project) do
    create(:project, :internal, namespace: source_user.namespace, updated_at: 2.hours.ago, path: 'C')
  end

  before do
    private_project.add_developer(current_user)
  end

  describe 'without a current user' do
    subject { finder.execute }

    it { is_expected.to eq([public_project]) }
  end

  describe 'with a current user' do
    subject { finder.execute(current_user) }

    context 'normal user' do
      it { is_expected.to eq([public_project, internal_project, private_project]) }
    end

    context 'external' do
      before do
        current_user.update!(external: true)
      end

      it { is_expected.to eq([public_project, private_project]) }
    end
  end
end
