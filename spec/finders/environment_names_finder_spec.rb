# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentNamesFinder do
  describe '#execute' do
    let!(:group) { create(:group) }
    let!(:project1) { create(:project, :public, namespace: group) }
    let!(:project2) { create(:project, :private, namespace: group) }
    let!(:user) { create(:user) }

    before do
      create(:environment, name: 'gstg', project: project1)
      create(:environment, name: 'gprd', project: project1)
      create(:environment, name: 'gprd', project: project2)
      create(:environment, name: 'gcny', project: project2)
    end

    context 'using a group and a group member' do
      it 'returns environment names for all projects' do
        group.add_developer(user)

        names = described_class.new(group, user).execute

        expect(names).to eq(%w[gcny gprd gstg])
      end
    end

    context 'using a group and a guest' do
      it 'returns environment names for all public projects' do
        names = described_class.new(group, user).execute

        expect(names).to eq(%w[gprd gstg])
      end
    end

    context 'using a public project and a project member' do
      it 'returns all the unique environment names' do
        project1.team.add_developer(user)

        names = described_class.new(project1, user).execute

        expect(names).to eq(%w[gprd gstg])
      end
    end

    context 'using a public project and a guest' do
      it 'returns all the unique environment names' do
        names = described_class.new(project1, user).execute

        expect(names).to eq(%w[gprd gstg])
      end
    end

    context 'using a private project and a guest' do
      it 'returns all the unique environment names' do
        names = described_class.new(project2, user).execute

        expect(names).to be_empty
      end
    end
  end
end
