# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::EnvironmentNamesFinder do
  describe '#execute' do
    let!(:group) { create(:group) }
    let!(:public_project) { create(:project, :public, namespace: group) }
    let_it_be_with_reload(:public_project_with_private_environments) { create(:project, :public) }
    let!(:private_project) { create(:project, :private, namespace: group) }
    let!(:user) { create(:user) }

    before do
      create(:environment, name: 'gstg', project: public_project)
      create(:environment, name: 'gprd', project: public_project)
      create(:environment, name: 'gprd', project: private_project)
      create(:environment, name: 'gcny', project: private_project)
      create(:environment, name: 'gprivprd', project: public_project_with_private_environments)
      create(:environment, name: 'gprivstg', project: public_project_with_private_environments)

      public_project_with_private_environments.update!(namespace: group)
      public_project_with_private_environments.project_feature.update!(environments_access_level: Featurable::PRIVATE)
    end

    context 'using a group' do
      context 'with a group developer' do
        it 'returns environment names for all projects' do
          group.add_developer(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gcny gprd gprivprd gprivstg gstg])
        end
      end

      context 'with a group reporter' do
        it 'returns environment names for all projects' do
          group.add_reporter(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gcny gprd gprivprd gprivstg gstg])
        end
      end

      context 'with a public project reporter' do
        it 'returns environment names for all public projects' do
          public_project.add_reporter(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'with a private project reporter' do
        it 'returns environment names for all public projects' do
          private_project.add_reporter(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gcny gprd gstg])
        end
      end

      context 'with a public project reporter which has private environments' do
        it 'returns environment names for public projects' do
          public_project_with_private_environments.add_reporter(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gprd gprivprd gprivstg gstg])
        end
      end

      context 'with a group guest' do
        it 'returns environment names for public projects' do
          group.add_guest(user)

          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'with a non-member' do
        it 'returns environment names for only public projects with public environments' do
          names = described_class.new(group, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'without a user' do
        it 'returns environment names for only public projects with public environments' do
          names = described_class.new(group).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end
    end

    context 'using a public project' do
      context 'with a project developer' do
        it 'returns all the unique environment names' do
          public_project.add_developer(user)

          names = described_class.new(public_project, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'with a project reporter' do
        it 'returns all the unique environment names' do
          public_project.add_reporter(user)

          names = described_class.new(public_project, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'with a project guest' do
        it 'returns all the unique environment names' do
          public_project.add_guest(user)

          names = described_class.new(public_project, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'with a non-member' do
        it 'returns all the unique environment names' do
          names = described_class.new(public_project, user).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end

      context 'without a user' do
        it 'returns all the unique environment names' do
          names = described_class.new(public_project).execute

          expect(names).to eq(%w[gprd gstg])
        end
      end
    end

    context 'using a private project' do
      context 'with a project developer' do
        it 'returns all the unique environment names' do
          private_project.add_developer(user)

          names = described_class.new(private_project, user).execute

          expect(names).to eq(%w[gcny gprd])
        end
      end

      context 'with a project reporter' do
        it 'returns all the unique environment names' do
          private_project.add_reporter(user)

          names = described_class.new(private_project, user).execute

          expect(names).to eq(%w[gcny gprd])
        end
      end

      context 'with a project guest' do
        it 'does not return any environment names' do
          private_project.add_guest(user)

          names = described_class.new(private_project, user).execute

          expect(names).to be_empty
        end
      end

      context 'with a non-member' do
        it 'does not return any environment names' do
          names = described_class.new(private_project, user).execute

          expect(names).to be_empty
        end
      end

      context 'without a user' do
        it 'does not return any environment names' do
          names = described_class.new(private_project).execute

          expect(names).to be_empty
        end
      end
    end
  end
end
