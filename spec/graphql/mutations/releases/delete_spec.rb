# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Releases::Delete do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:non_project_member) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:tag) { 'v1.1.0'}
  let_it_be(:release) { create(:release, project: project, tag: tag) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      tag: tag
    }
  end

  before do
    project.add_reporter(reporter)
    project.add_developer(developer)
    project.add_maintainer(maintainer)
  end

  shared_examples 'unauthorized or not found error' do
    it 'raises a Gitlab::Graphql::Errors::ResourceNotAvailable error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, "The resource that you are attempting to access does not exist or you don't have permission to perform this action")
    end
  end

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'when the current user has access to create releases' do
      let(:current_user) { developer }

      it 'deletes the release' do
        expect { subject }.to change { Release.count }.by(-1)
      end

      it 'returns the deleted release' do
        expect(subject[:release].tag).to eq(tag)
      end

      it 'does not remove the Git tag associated with the deleted release' do
        expect { subject }.not_to change { Project.find_by_id(project.id).repository.tag_count }
      end

      it 'returns no errors' do
        expect(subject[:errors]).to eq([])
      end

      context 'with protected tag' do
        context 'when user has access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

          it 'does not have errors' do
            subject

            expect(resolve).to include(errors: [])
          end
        end

        context 'when user does not have access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

          it 'has an access error' do
            subject

            expect(resolve).to include(errors: ['Access Denied'])
          end
        end
      end

      context 'validation' do
        context 'when the release does not exist' do
          let(:mutation_arguments) { super().merge(tag: 'not-a-real-release') }

          it 'returns the release as nil' do
            expect(subject[:release]).to be_nil
          end

          it 'returns an errors-at-data message' do
            expect(subject[:errors]).to eq(['Release does not exist'])
          end
        end

        context 'when the project does not exist' do
          let(:mutation_arguments) { super().merge(project_path: 'not/a/real/path') }

          it_behaves_like 'unauthorized or not found error'
        end
      end
    end

    context "when the current user doesn't have access to update releases" do
      context 'when the user is a reporter' do
        let(:current_user) { reporter }

        it_behaves_like 'unauthorized or not found error'
      end

      context 'when the user is a non-project member' do
        let(:current_user) { non_project_member }

        it_behaves_like 'unauthorized or not found error'
      end
    end
  end
end
