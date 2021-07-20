# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Releases::Update do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let_it_be(:tag) { 'v1.1.0'}
  let_it_be(:name) { 'Version 1.0'}
  let_it_be(:description) { 'The first release :rocket:' }
  let_it_be(:released_at) { Time.parse('2018-12-10').utc }
  let_it_be(:created_at) { Time.parse('2018-11-05').utc }
  let_it_be(:milestones) { [milestone_12_3.title, milestone_12_4.title] }

  let_it_be(:release) do
    create(:release, project: project, tag: tag, name: name,
           description: description, released_at: released_at,
           created_at: created_at, milestones: [milestone_12_3, milestone_12_4])
  end

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      tag: tag
    }
  end

  around do |example|
    freeze_time { example.run }
  end

  before do
    project.add_reporter(reporter)
    project.add_developer(developer)
  end

  shared_examples 'no changes to the release except for the' do |except_for|
    it 'does not change other release properties' do
      expect(updated_release.project).to eq(project)
      expect(updated_release.tag).to eq(tag)

      expect(updated_release.name).to eq(name) unless except_for == :name
      expect(updated_release.description).to eq(description) unless except_for == :description
      expect(updated_release.released_at).to eq(released_at) unless except_for == :released_at
      expect(updated_release.milestones.order_by_dates_and_title).to eq([milestone_12_3, milestone_12_4]) unless except_for == :milestones
    end
  end

  shared_examples 'validation error with message' do |message|
    it 'returns the updated release as nil' do
      expect(updated_release).to be_nil
    end

    it 'returns a validation error' do
      expect(subject[:errors]).to eq([message])
    end
  end

  describe '#ready?' do
    let(:current_user) { developer }

    subject(:ready) do
      mutation.ready?(**mutation_arguments)
    end

    context 'when released_at is included as an argument but is passed nil' do
      let(:mutation_arguments) { super().merge(released_at: nil) }

      it 'raises a validation error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'if the releasedAt argument is provided, it cannot be null')
      end
    end

    context 'when milestones is included as an argument but is passed nil' do
      let(:mutation_arguments) { super().merge(milestones: nil) }

      it 'raises a validation error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'if the milestones argument is provided, it cannot be null')
      end
    end
  end

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    let(:updated_release) { subject[:release] }

    context 'when the current user has access to create releases' do
      let(:current_user) { developer }

      context 'name' do
        let(:mutation_arguments) { super().merge(name: updated_name) }

        context 'when a new name is provided' do
          let(:updated_name) { 'Updated name' }

          it 'updates the name' do
            expect(updated_release.name).to eq(updated_name)
          end

          it_behaves_like 'no changes to the release except for the', :name

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
        end

        context 'when nil is provided' do
          let(:updated_name) { nil }

          it 'updates the name to be the tag name' do
            expect(updated_release.name).to eq(tag)
          end

          it_behaves_like 'no changes to the release except for the', :name
        end
      end

      context 'description' do
        let(:mutation_arguments) { super().merge(description: updated_description) }

        context 'when a new description is provided' do
          let(:updated_description) { 'Updated description' }

          it 'updates the description' do
            expect(updated_release.description).to eq(updated_description)
          end

          it_behaves_like 'no changes to the release except for the', :description
        end

        context 'when nil is provided' do
          let(:updated_description) { nil }

          it 'updates the description to nil' do
            expect(updated_release.description).to eq(nil)
          end

          it_behaves_like 'no changes to the release except for the', :description
        end
      end

      context 'released_at' do
        let(:mutation_arguments) { super().merge(released_at: updated_released_at) }

        context 'when a new released_at is provided' do
          let(:updated_released_at) { Time.parse('2020-12-10').utc }

          it 'updates the released_at' do
            expect(updated_release.released_at).to eq(updated_released_at)
          end

          it_behaves_like 'no changes to the release except for the', :released_at
        end
      end

      context 'milestones' do
        let(:mutation_arguments) { super().merge(milestones: updated_milestones) }

        context 'when a new set of milestones is provided provided' do
          let(:updated_milestones) { [milestone_12_3.title] }

          it 'updates the milestone associations' do
            expect(updated_release.milestones).to eq([milestone_12_3])
          end

          it_behaves_like 'no changes to the release except for the', :milestones
        end

        context 'when an empty array is provided' do
          let(:updated_milestones) { [] }

          it 'removes all milestone associations' do
            expect(updated_release.milestones).to eq([])
          end

          it_behaves_like 'no changes to the release except for the', :milestones
        end

        context 'when a non-existent milestone title is provided' do
          let(:updated_milestones) { ['not real'] }

          it_behaves_like 'validation error with message', 'Milestone(s) not found: not real'
        end

        context 'when a milestone title from a different project is provided' do
          let(:milestone_in_different_project) { create(:milestone, title: 'milestone in different project') }
          let(:updated_milestones) { [milestone_in_different_project.title] }

          it_behaves_like 'validation error with message', 'Milestone(s) not found: milestone in different project'
        end
      end

      context 'validation' do
        context 'when no updated fields are provided' do
          it_behaves_like 'validation error with message', 'params is empty'
        end

        context 'when the tag does not exist' do
          let(:mutation_arguments) { super().merge(tag: 'not-a-real-tag') }

          it_behaves_like 'validation error with message', 'Tag does not exist'
        end

        context 'when the project does not exist' do
          let(:mutation_arguments) { super().merge(project_path: 'not/a/real/path') }

          it 'raises an error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, "The resource that you are attempting to access does not exist or you don't have permission to perform this action")
          end
        end
      end
    end

    context "when the current user doesn't have access to update releases" do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, "The resource that you are attempting to access does not exist or you don't have permission to perform this action")
      end
    end
  end
end
